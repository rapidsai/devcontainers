#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

base_ref="${FEATURE_VERSION_BASE_SHA:-${1:-}}"
auto_bump=false
if [[ -z "${base_ref}" ]]; then
  auto_bump_value="${FEATURE_VERSION_AUTO_BUMP:-}"
  if [[ -z "${auto_bump_value}" ]]; then
    auto_bump_value="$(git config --get devcontainers.auto-bump-feature-versions 2>/dev/null || true)"
  fi

  case "${auto_bump_value}" in
    "" | 0 | false | no | off)
      ;;
    1 | true | yes | on)
      auto_bump=true
      ;;
    *)
      echo "FEATURE_VERSION_AUTO_BUMP must be a boolean value, got '${auto_bump_value}'." >&2
      exit 2
      ;;
  esac
fi

if [[ -n "${base_ref}" ]]; then
  if ! git cat-file -e "${base_ref}^{commit}" 2>/dev/null; then
    echo "Feature version check cannot find base commit '${base_ref}'." >&2
    echo "Fetch the base branch history before running this check." >&2
    exit 2
  fi
  old_prefix="${base_ref}:"
  new_prefix="HEAD:"
  history_ref="${base_ref}"
  diff_command=(
    git diff --name-only -z --diff-filter=ACDMRTUXB
    "${base_ref}" HEAD -- features/common features/src
  )
else
  if git diff --cached --quiet -- features/common features/src; then
    exit 0
  fi
  old_prefix="HEAD:"
  new_prefix=":"
  history_ref="HEAD"
  diff_command=(
    git diff --cached --name-only -z --diff-filter=ACDMRTUXB --
    features/common features/src
  )
fi

affected_features="$(mktemp)"
changed_version_features="$(mktemp)"
unchanged_version_failures="$(mktemp)"
historical_version_failures="$(mktemp)"
auto_bump_features="$(mktemp)"
auto_bump_plan="$(mktemp)"
auto_bump_errors="$(mktemp)"
trap 'rm -f \
  "${affected_features}" \
  "${changed_version_features}" \
  "${unchanged_version_failures}" \
  "${historical_version_failures}" \
  "${auto_bump_features}" \
  "${auto_bump_plan}" \
  "${auto_bump_errors}"' EXIT

object_exists() {
  git cat-file -e "${1}${2}" 2>/dev/null
}

read_object() {
  git show "${1}${2}"
}

mark_all_features() {
  local manifest feature
  for manifest in features/src/*/devcontainer-feature.json; do
    [[ -f "${manifest}" ]] || continue
    feature="${manifest#features/src/}"
    printf '%s\n' "${feature%%/*}" >> "${affected_features}"
  done
}

descriptor_payload_changed() {
  local manifest="$1"
  local old_payload new_payload

  # A new or removed feature has no prior version that can be bumped.
  object_exists "${old_prefix}" "${manifest}" || return 1
  object_exists "${new_prefix}" "${manifest}" || return 1

  old_payload="$(read_object "${old_prefix}" "${manifest}" | jq -cS 'del(.version)')"
  new_payload="$(read_object "${new_prefix}" "${manifest}" | jq -cS 'del(.version)')"
  [[ "${old_payload}" != "${new_payload}" ]]
}

is_numeric_version() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

version_is_greater() {
  local candidate="$1"
  local previous="$2"
  local candidate_major candidate_minor candidate_patch candidate_rest
  local previous_major previous_minor previous_patch previous_rest

  is_numeric_version "${candidate}" || return 2
  is_numeric_version "${previous}" || return 2

  candidate_major="${candidate%%.*}"
  candidate_rest="${candidate#*.}"
  candidate_minor="${candidate_rest%%.*}"
  candidate_patch="${candidate_rest#*.}"
  previous_major="${previous%%.*}"
  previous_rest="${previous#*.}"
  previous_minor="${previous_rest%%.*}"
  previous_patch="${previous_rest#*.}"

  if ((10#${candidate_major} != 10#${previous_major})); then
    ((10#${candidate_major} > 10#${previous_major}))
  elif ((10#${candidate_minor} != 10#${previous_minor})); then
    ((10#${candidate_minor} > 10#${previous_minor}))
  else
    ((10#${candidate_patch} > 10#${previous_patch}))
  fi
}

highest_historical_version() {
  local manifest="$1"
  local candidate="$2"
  local candidate_series="${candidate%.*}"
  local version highest=""

  # Read both sides of every historical version-field change. This retains
  # high-water marks that a later release-preparation commit may have reset.
  while IFS= read -r version; do
    [[ "${version%.*}" == "${candidate_series}" ]] || continue
    if [[ -z "${highest}" ]] || version_is_greater "${version}" "${highest}"; then
      highest="${version}"
    fi
  done < <(
    git log -p --format= "${history_ref}" -- "${manifest}" \
      | sed -nE 's/^[+-].*"version"[[:space:]]*:[[:space:]]*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/p'
  )

  printf '%s\n' "${highest}"
}

next_patch_version() {
  local version="$1"
  local patch="${version##*.}"

  printf '%s.%d\n' "${version%.*}" "$((10#${patch} + 1))"
}

rewrite_manifest_version() {
  local manifest="$1"
  local old_version="$2"
  local new_version="$3"

  OLD_VERSION="${old_version}" NEW_VERSION="${new_version}" perl -pi -e \
    '$count += s{("version"\s*:\s*)"\Q$ENV{OLD_VERSION}\E"}{$1 . qq{"$ENV{NEW_VERSION}"}}e; END { die "version replacement failed\n" unless $count == 1; }' \
    "${manifest}"
}

while IFS= read -r -d '' path; do
  if [[ "${path}" == features/common/* ]]; then
    mark_all_features
    continue
  fi

  [[ "${path}" == features/src/*/* ]] || continue
  feature="${path#features/src/}"
  feature="${feature%%/*}"
  relative_path="${path#features/src/"${feature}"/}"

  # These files are generated or explanatory and are not feature payload.
  if [[ "${relative_path}" == "README.md" || "${relative_path}" == "NOTES.md" ]]; then
    continue
  fi

  if [[ "${relative_path}" == "devcontainer-feature.json" ]]; then
    if object_exists "${old_prefix}" "${path}" && object_exists "${new_prefix}" "${path}"; then
      old_version="$(read_object "${old_prefix}" "${path}" | jq -er '.version | strings')"
      new_version="$(read_object "${new_prefix}" "${path}" | jq -er '.version | strings')"
      if [[ "${old_version}" != "${new_version}" ]]; then
        printf '%s\n' "${feature}" >> "${changed_version_features}"
      fi
    fi
    if descriptor_payload_changed "${path}"; then
      printf '%s\n' "${feature}" >> "${affected_features}"
    fi
  else
    printf '%s\n' "${feature}" >> "${affected_features}"
  fi
done < <("${diff_command[@]}")

while IFS= read -r feature; do
  manifest="features/src/${feature}/devcontainer-feature.json"

  # Adding or removing a complete feature does not reuse an existing version.
  object_exists "${old_prefix}" "${manifest}" || continue
  object_exists "${new_prefix}" "${manifest}" || continue

  old_version="$(read_object "${old_prefix}" "${manifest}" | jq -er '.version | strings')"
  new_version="$(read_object "${new_prefix}" "${manifest}" | jq -er '.version | strings')"
  if [[ "${old_version}" == "${new_version}" ]]; then
    printf '%s\t%s\n' "${feature}" "${new_version}" >> "${unchanged_version_failures}"
  fi
done < <(sort -u "${affected_features}")

while IFS= read -r feature; do
  manifest="features/src/${feature}/devcontainer-feature.json"
  new_version="$(read_object "${new_prefix}" "${manifest}" | jq -er '.version | strings')"

  if ! is_numeric_version "${new_version}"; then
    printf '%s\t%s\t%s\n' "${feature}" "${new_version}" "numeric MAJOR.MINOR.PATCH" \
      >> "${historical_version_failures}"
  else
    highest_version="$(highest_historical_version "${manifest}" "${new_version}")"
    if [[ -n "${highest_version}" ]] && ! version_is_greater "${new_version}" "${highest_version}"; then
      printf '%s\t%s\t%s\n' "${feature}" "${new_version}" "${highest_version}" \
        >> "${historical_version_failures}"
    fi
  fi
done < <(sort -u "${changed_version_features}")

if [[ "${auto_bump}" == true ]]; then
  {
    cut -f1 "${unchanged_version_failures}"
    cut -f1 "${historical_version_failures}"
  } | sort -u > "${auto_bump_features}"

  while IFS= read -r feature; do
    [[ -n "${feature}" ]] || continue
    manifest="features/src/${feature}/devcontainer-feature.json"
    current_version="$(read_object "${new_prefix}" "${manifest}" | jq -er '.version | strings')"

    if ! is_numeric_version "${current_version}"; then
      printf '%s\t%s\n' "${feature}" \
        "cannot auto-bump non-numeric version ${current_version}" >> "${auto_bump_errors}"
      continue
    fi

    if ! git diff --quiet -- "${manifest}"; then
      printf '%s\t%s\n' "${feature}" \
        "has unstaged manifest changes; refusing to overwrite them" >> "${auto_bump_errors}"
      continue
    fi

    highest_version="$(highest_historical_version "${manifest}" "${current_version}")"
    bump_from="${current_version}"
    if [[ -n "${highest_version}" ]] && version_is_greater "${highest_version}" "${bump_from}"; then
      bump_from="${highest_version}"
    fi
    next_version="$(next_patch_version "${bump_from}")"
    printf '%s\t%s\t%s\t%s\n' \
      "${feature}" "${current_version}" "${next_version}" "${manifest}" >> "${auto_bump_plan}"
  done < "${auto_bump_features}"

  if [[ ! -s "${auto_bump_errors}" && -s "${auto_bump_plan}" ]]; then
    while IFS=$'\t' read -r feature current_version next_version manifest; do
      rewrite_manifest_version "${manifest}" "${current_version}" "${next_version}"
    done < "${auto_bump_plan}"

    echo "Automatically updated required feature versions:" >&2
    while IFS=$'\t' read -r feature current_version next_version manifest; do
      echo "  - ${feature}: ${current_version} -> ${next_version}" >&2
    done < "${auto_bump_plan}"
    echo >&2
    echo "Review and stage the updated manifests, then retry the commit." >&2
    exit 1
  fi

  if [[ -s "${auto_bump_errors}" ]]; then
    echo "Feature versions could not be updated automatically:" >&2
    while IFS=$'\t' read -r feature message; do
      echo "  - ${feature}: ${message}" >&2
    done < "${auto_bump_errors}"
    echo >&2
  fi
fi

status=0
if [[ -s "${unchanged_version_failures}" ]]; then
  echo "Feature contents changed without changing the published version:" >&2
  while IFS=$'\t' read -r feature version; do
    echo "  - ${feature}: features/src/${feature}/devcontainer-feature.json is still ${version}" >&2
  done < "${unchanged_version_failures}"
  echo >&2
  echo "Change each listed manifest's 'version' value and stage it with the feature changes." >&2
  echo "Files under features/common are copied into every feature, so they require every feature version to change." >&2
  status=1
fi

if [[ -s "${historical_version_failures}" ]]; then
  if ((status != 0)); then
    echo >&2
  fi
  echo "Feature versions must be newer than every version previously used in the target history:" >&2
  while IFS=$'\t' read -r feature version highest_version; do
    echo "  - ${feature}: ${version} is not newer than ${highest_version}" >&2
  done < "${historical_version_failures}"
  echo >&2
  echo "Choose a version above the historical high-water mark; the current file may contain an earlier reset value." >&2
  status=1
fi

if ((status != 0)) && [[ -z "${base_ref}" && "${auto_bump}" == false ]]; then
  echo >&2
  echo "For formatter-style automatic bumps in this checkout, opt in with:" >&2
  echo "  git config devcontainers.auto-bump-feature-versions true" >&2
  echo "Or enable it for one command with FEATURE_VERSION_AUTO_BUMP=1." >&2
fi

exit "${status}"
