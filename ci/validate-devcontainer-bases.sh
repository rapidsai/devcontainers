#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

full_version="$(tr -d '[:space:]' < VERSION)"
if [[ ! "${full_version}" =~ ^[0-9]{2}\.[0-9]{2}\.[0-9]{2}$ ]]; then
  echo "VERSION must use YY.MM.PP format; found '${full_version}'" >&2
  exit 1
fi
short_version="${full_version%.*}"

expected_tags="$(mktemp)"
trap 'rm -f "${expected_tags}"' EXIT

# Recreate the visible part of every Linux image name from matrix.yml. Hidden
# features affect image contents but, by design, do not appear in image tags.
yq --yaml-fix-merge-anchor-to-spec -eMo json matrix.yml \
  | jq -r --arg version "${short_version}" '
      .include[]
      | select(.os != "windows")
      | (.os | gsub(":"; "")) as $os
      | .images[]
      | (.features
          | map(
              select(.hide != true)
              | (.name | split("/")[-1] | split(":")[0])
                + (.version // "" | tostring)
                + (.suffix // "" | tostring)
            )
          | (. + [$os])
          | join("-")
        ) as $name
      # The release publishes both the OS-qualified tag and an OS-free alias.
      | [
          $version + "-cpp-" + $name,
          $version + "-cpp-" + ($name | sub("-" + $os + "$"; ""))
        ]
      | .[]
    ' \
  | sort -u > "${expected_tags}"

status=0
while IFS=$'\t' read -r file base; do
  [[ "${base}" == rapidsai/devcontainers:* ]] || continue
  tag="${base#rapidsai/devcontainers:}"
  if ! grep -Fqx -- "${tag}" "${expected_tags}"; then
    echo "${file}: BASE '${base}' is not produced by matrix.yml" >&2
    status=1
  fi
done < <(
  find .devcontainer -name devcontainer.json -exec \
    jq -r '[input_filename, (.build.args.BASE // "")] | @tsv' {} +
)

exit "${status}"
