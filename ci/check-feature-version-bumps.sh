#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

base_ref="${FEATURE_VERSION_BASE_SHA:-${1:-}}"
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
trap 'rm -f \
  "${affected_features}" \
  "${changed_version_features}" \
  "${unchanged_version_failures}" \
  "${historical_version_failures}"' EXIT

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

exit "${status}"
