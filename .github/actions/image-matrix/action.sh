#! /usr/bin/env bash

# cd to the repo root
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../";

full_matrix="0";

case "${1:-}" in
   "1" | "true" ) full_matrix="1"; shift;;
   "0" | "false") full_matrix="0"; shift;;
esac

features="${1:-"[]"}";
scenarios="${2:-"[]"}";
files="${@:3}";

# Select all images that use a changed feature

common_features="cpp|gitlab-cli";

features="$(echo                        \
  "${features}"  `# ["foo", "bar"]`     \
  "${scenarios}" `# ["baz"]`            \
| jq -e -s 'flatten'                    \
| jq -e 'map(select(. != ""))'          \
| jq -e 'map(gsub("^utils$";   "cpp"))' \
| jq -e 'map(gsub("^cmake$";   "cpp"))' \
| jq -e 'map(gsub("^ninja$";   "cpp"))' \
| jq -e 'map(gsub("^sccache$"; "cpp"))' \
| jq -ec 'unique'                       \
|| echo ''                              \
)";

if `# Include all images if full_matrix is true`         \
   [ "${full_matrix}" == "1" ]                           \
   `# Include all images if matrix or workflows changed` \
|| echo "${files}" | grep -qE '^(\.github/|matrix\.yml)' \
   `# Include all images if cmake, ninja, sccache, `     \
   `# gitlab-cli, or utils features changed`             \
|| echo "${features}" | grep -qE "(${common_features})"  \
; then
  features="$(                                                  \
      find features/src -mindepth 1 -maxdepth 1 -type d -print0 \
    | xargs -0 -r -I% sh -c 'echo -n "\"$(basename %)\","'      \
  )";
  features="[${features%,}]";
fi

# Select images that include at least one of the changed features

changed_images="$( \
  cat matrix.yml \
| yq -eMo json    \
| jq -eMc --argjson xs "$features" '
  .include
  | map(.os as $os
    | .images
    | map(.features
      | select(any(IN(.name; $xs[])))
      | {
        os: $os,
        features: .,
        name: (.
          | map(.
            | select(.hide != true)
            | (.name | split("/")[-1] | split(":")[0]) + .version)
          )
          | (. + [$os])
          | join(" "),
      }
    )
  )
  | flatten | unique'
)";

if [[ "$changed_images" == "null" ]]; then changed_images=""; fi

# Concatenate changed feature/image lists and write the matrix
cat <<EOF
matrix={"include":${changed_images:-"[]"}}
EOF
