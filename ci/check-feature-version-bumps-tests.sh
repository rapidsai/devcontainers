#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
checker="${repo_root}/ci/check-feature-version-bumps.sh"
test_root="$(mktemp -d)"
trap 'rm -rf "${test_root}"' EXIT

# A CI base SHA from the outer repository is meaningless inside the fixtures.
unset FEATURE_VERSION_BASE_SHA

fixture_dir=""
output_file=""

make_fixture() {
  local name="$1"

  fixture_dir="${test_root}/${name}"
  output_file="${fixture_dir}/checker-output"
  mkdir -p \
    "${fixture_dir}/ci" \
    "${fixture_dir}/features/common" \
    "${fixture_dir}/features/src/alpha" \
    "${fixture_dir}/features/src/beta"
  cp "${checker}" "${fixture_dir}/ci/check-feature-version-bumps.sh"
  printf '%s\n' '#!/usr/bin/env bash' 'echo alpha' > "${fixture_dir}/features/src/alpha/install.sh"
  printf '%s\n' '#!/usr/bin/env bash' 'echo beta' > "${fixture_dir}/features/src/beta/install.sh"
  printf '%s\n' '# Alpha' > "${fixture_dir}/features/src/alpha/README.md"
  printf '%s\n' 'echo common' > "${fixture_dir}/features/common/utilities.sh"
  printf '%s\n' \
    '{"id":"alpha","version":"1.0.0","description":"Alpha"}' \
    > "${fixture_dir}/features/src/alpha/devcontainer-feature.json"
  printf '%s\n' \
    '{"id":"beta","version":"1.0.0","description":"Beta"}' \
    > "${fixture_dir}/features/src/beta/devcontainer-feature.json"

  git -C "${fixture_dir}" init -q
  git -C "${fixture_dir}" config user.email test@example.com
  git -C "${fixture_dir}" config user.name "Feature version check tests"
  git -C "${fixture_dir}" config commit.gpgsign false
  git -C "${fixture_dir}" add .
  git -C "${fixture_dir}" commit -qm baseline
}

bump_feature_to() {
  local feature="$1"
  local version="$2"
  local manifest="${fixture_dir}/features/src/${feature}/devcontainer-feature.json"
  local temporary="${manifest}.tmp"

  jq --arg version "${version}" '.version = $version' "${manifest}" > "${temporary}"
  mv "${temporary}" "${manifest}"
  git -C "${fixture_dir}" add "features/src/${feature}/devcontainer-feature.json"
}

bump_feature() {
  bump_feature_to "$1" 1.0.1
}

run_checker() {
  (
    cd "${fixture_dir}"
    ./ci/check-feature-version-bumps.sh "$@"
  ) > "${output_file}" 2>&1
}

run_checker_with_auto_bump() {
  (
    cd "${fixture_dir}"
    FEATURE_VERSION_AUTO_BUMP=1 ./ci/check-feature-version-bumps.sh "$@"
  ) > "${output_file}" 2>&1
}

feature_version() {
  jq -er '.version' "${fixture_dir}/features/src/$1/devcontainer-feature.json"
}

expect_success() {
  local name="$1"
  shift
  if ! run_checker "$@"; then
    echo "FAIL: ${name} should have passed" >&2
    sed 's/^/  /' "${output_file}" >&2
    exit 1
  fi
}

expect_failure() {
  local name="$1"
  shift
  if run_checker "$@"; then
    echo "FAIL: ${name} should have failed" >&2
    exit 1
  fi
}

expect_auto_bump() {
  local name="$1"
  shift
  if run_checker_with_auto_bump "$@"; then
    echo "FAIL: ${name} should have stopped the commit after updating files" >&2
    exit 1
  fi
}

make_fixture payload_without_bump
printf '%s\n' 'echo changed' >> "${fixture_dir}/features/src/alpha/install.sh"
git -C "${fixture_dir}" add features/src/alpha/install.sh
expect_failure payload_without_bump
grep -q 'alpha:.*still 1.0.0' "${output_file}"
grep -q 'git config devcontainers.auto-bump-feature-versions true' "${output_file}"

make_fixture payload_with_auto_bump
printf '%s\n' 'echo changed' >> "${fixture_dir}/features/src/alpha/install.sh"
git -C "${fixture_dir}" add features/src/alpha/install.sh
expect_auto_bump payload_with_auto_bump
[[ "$(feature_version alpha)" == 1.0.1 ]]
grep -q 'alpha: 1.0.0 -> 1.0.1' "${output_file}"
git -C "${fixture_dir}" add features/src/alpha/devcontainer-feature.json
expect_success payload_with_auto_bump_retry

make_fixture payload_with_auto_bump_from_git_config
git -C "${fixture_dir}" config devcontainers.auto-bump-feature-versions true
printf '%s\n' 'echo changed' >> "${fixture_dir}/features/src/alpha/install.sh"
git -C "${fixture_dir}" add features/src/alpha/install.sh
expect_failure payload_with_auto_bump_from_git_config
[[ "$(feature_version alpha)" == 1.0.1 ]]

make_fixture payload_with_bump
printf '%s\n' 'echo changed' >> "${fixture_dir}/features/src/alpha/install.sh"
git -C "${fixture_dir}" add features/src/alpha/install.sh
bump_feature alpha
expect_success payload_with_bump

make_fixture descriptor_payload_without_bump
manifest="${fixture_dir}/features/src/alpha/devcontainer-feature.json"
jq '.description = "Changed"' "${manifest}" > "${manifest}.tmp"
mv "${manifest}.tmp" "${manifest}"
git -C "${fixture_dir}" add features/src/alpha/devcontainer-feature.json
expect_failure descriptor_payload_without_bump

make_fixture version_only
bump_feature alpha
expect_success version_only

make_fixture historical_version_reuse
bump_feature_to alpha 1.0.5
git -C "${fixture_dir}" commit -qm high_water_mark
bump_feature_to alpha 1.0.0
git -C "${fixture_dir}" commit -qm reset
base_sha="$(git -C "${fixture_dir}" rev-parse HEAD)"
bump_feature_to alpha 1.0.1
expect_failure historical_version_reuse
grep -q 'alpha: 1.0.1 is not newer than 1.0.5' "${output_file}"
git -C "${fixture_dir}" commit -qm reused_version
expect_failure historical_version_reuse_in_pull_request "${base_sha}"
bump_feature_to alpha 1.0.6
git -C "${fixture_dir}" commit -qm version_above_high_water_mark
expect_success version_above_high_water_mark_in_pull_request "${base_sha}"

make_fixture historical_version_reset
bump_feature_to alpha 1.0.5
git -C "${fixture_dir}" commit -qm high_water_mark
bump_feature_to alpha 1.0.0
expect_failure historical_version_reset
grep -q 'alpha: 1.0.0 is not newer than 1.0.5' "${output_file}"

make_fixture payload_auto_bump_above_high_water_mark
bump_feature_to alpha 1.0.5
git -C "${fixture_dir}" commit -qm high_water_mark
bump_feature_to alpha 1.0.0
git -C "${fixture_dir}" commit -qm reset
printf '%s\n' 'echo changed' >> "${fixture_dir}/features/src/alpha/install.sh"
git -C "${fixture_dir}" add features/src/alpha/install.sh
expect_auto_bump payload_auto_bump_above_high_water_mark
[[ "$(feature_version alpha)" == 1.0.6 ]]
grep -q 'alpha: 1.0.0 -> 1.0.6' "${output_file}"

make_fixture other_version_series_ignored
bump_feature_to alpha 1.1.5
git -C "${fixture_dir}" commit -qm other_series_high_water_mark
bump_feature_to alpha 1.0.0
git -C "${fixture_dir}" commit -qm reset_original_series
bump_feature_to alpha 1.0.1
expect_success other_version_series_ignored

make_fixture auto_bump_ignores_other_version_series
bump_feature_to alpha 1.1.5
git -C "${fixture_dir}" commit -qm other_series_high_water_mark
bump_feature_to alpha 1.0.0
git -C "${fixture_dir}" commit -qm reset_original_series
printf '%s\n' 'echo changed' >> "${fixture_dir}/features/src/alpha/install.sh"
git -C "${fixture_dir}" add features/src/alpha/install.sh
expect_auto_bump auto_bump_ignores_other_version_series
[[ "$(feature_version alpha)" == 1.0.1 ]]

make_fixture generated_docs_only
printf '%s\n' 'Generated details' >> "${fixture_dir}/features/src/alpha/README.md"
git -C "${fixture_dir}" add features/src/alpha/README.md
expect_success generated_docs_only

make_fixture shared_payload_without_bumps
printf '%s\n' 'echo changed' >> "${fixture_dir}/features/common/utilities.sh"
git -C "${fixture_dir}" add features/common/utilities.sh
expect_failure shared_payload_without_bumps
grep -q 'alpha:.*still 1.0.0' "${output_file}"
grep -q 'beta:.*still 1.0.0' "${output_file}"

make_fixture shared_payload_with_auto_bumps
printf '%s\n' 'echo changed' >> "${fixture_dir}/features/common/utilities.sh"
git -C "${fixture_dir}" add features/common/utilities.sh
expect_auto_bump shared_payload_with_auto_bumps
[[ "$(feature_version alpha)" == 1.0.1 ]]
[[ "$(feature_version beta)" == 1.0.1 ]]

make_fixture auto_bump_refuses_unstaged_manifest_changes
printf '%s\n' 'echo changed' >> "${fixture_dir}/features/src/alpha/install.sh"
git -C "${fixture_dir}" add features/src/alpha/install.sh
manifest="${fixture_dir}/features/src/alpha/devcontainer-feature.json"
jq '.description = "Unstaged change"' "${manifest}" > "${manifest}.tmp"
mv "${manifest}.tmp" "${manifest}"
expect_auto_bump auto_bump_refuses_unstaged_manifest_changes
[[ "$(feature_version alpha)" == 1.0.0 ]]
grep -q 'has unstaged manifest changes; refusing to overwrite them' "${output_file}"

make_fixture shared_auto_bump_is_atomic
printf '%s\n' 'echo changed' >> "${fixture_dir}/features/common/utilities.sh"
git -C "${fixture_dir}" add features/common/utilities.sh
manifest="${fixture_dir}/features/src/beta/devcontainer-feature.json"
jq '.description = "Unstaged change"' "${manifest}" > "${manifest}.tmp"
mv "${manifest}.tmp" "${manifest}"
expect_auto_bump shared_auto_bump_is_atomic
[[ "$(feature_version alpha)" == 1.0.0 ]]
[[ "$(feature_version beta)" == 1.0.0 ]]

make_fixture shared_payload_with_bumps
printf '%s\n' 'echo changed' >> "${fixture_dir}/features/common/utilities.sh"
git -C "${fixture_dir}" add features/common/utilities.sh
bump_feature alpha
bump_feature beta
expect_success shared_payload_with_bumps

make_fixture deleted_payload_without_bump
git -C "${fixture_dir}" rm -q features/src/alpha/install.sh
expect_failure deleted_payload_without_bump

make_fixture new_feature
mkdir -p "${fixture_dir}/features/src/gamma"
printf '%s\n' '#!/usr/bin/env bash' 'echo gamma' > "${fixture_dir}/features/src/gamma/install.sh"
printf '%s\n' \
  '{"id":"gamma","version":"1.0.0","description":"Gamma"}' \
  > "${fixture_dir}/features/src/gamma/devcontainer-feature.json"
git -C "${fixture_dir}" add features/src/gamma
expect_success new_feature

make_fixture pull_request_range
base_sha="$(git -C "${fixture_dir}" rev-parse HEAD)"
printf '%s\n' 'echo changed' >> "${fixture_dir}/features/src/alpha/install.sh"
git -C "${fixture_dir}" add features/src/alpha/install.sh
git -C "${fixture_dir}" commit -qm payload
expect_failure pull_request_range_without_bump "${base_sha}"
bump_feature alpha
git -C "${fixture_dir}" commit -qm bump
expect_success pull_request_range_with_bump "${base_sha}"

make_fixture pull_request_range_is_always_check_only
base_sha="$(git -C "${fixture_dir}" rev-parse HEAD)"
printf '%s\n' 'echo changed' >> "${fixture_dir}/features/src/alpha/install.sh"
git -C "${fixture_dir}" add features/src/alpha/install.sh
git -C "${fixture_dir}" commit -qm payload
expect_auto_bump pull_request_range_is_always_check_only "${base_sha}"
[[ "$(feature_version alpha)" == 1.0.0 ]]
if grep -q 'Automatically updated required feature versions' "${output_file}"; then
  echo "FAIL: pull-request checking must not modify feature versions" >&2
  exit 1
fi

echo "All feature version bump checks passed."
