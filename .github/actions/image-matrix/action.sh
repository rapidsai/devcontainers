#! /usr/bin/env bash

# cd to the repo root
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../";

full_matrix="${1:-"false"}";
features="${2:-"[]"}";
scenarios="${3:-"[]"}";
files="${@:4}";

if `# Include all images if full_matrix is true`                \
   [ "${full_matrix}" != "false" ]                              \
   `# Include all images if utils feature changed`              \
|| echo "${features}"  | grep -q '^utils$'                      \
|| echo "${scenarios}" | grep -q '^utils$'                      \
   `# Include all images if matrix or workflows changed`        \
|| echo "$files" | grep -q -E '^(\.github/|images/matrix\.yml)' \
; then
  files="$(find images -mindepth 1 -maxdepth 1 -type d)";
fi

changed_images="";

# Select the matrix of images whose source files changed
if echo "$files" | grep -q '^images/'; then

  imgs="$(                 \
    for x in ${files}; do  \
      x=${x##images/};     \
      echo "\"${x%%/*}\""; \
    done                   \
  )";

  keys="$(                          \
    echo ${imgs}                    \
  | tr '[:lower:]' '[:upper:]'      \
  | jq -cs 'map(split("-") | sort)' \
  )";

  changed_images="$(              \
    cat images/matrix.yml         \
  | yq -e -o json --no-colors     \
  | jq -ceM --argjson xs "$keys"  \
    'map(select(keys == $xs[]))'  \
 || echo ''
  )";

fi

# Select all images that use a changed feature
changed_features="$(echo "${features}" "${scenarios}"      \
| jq -e -s 'flatten'                                       \
| jq -e 'map(select(. != ""))'                             \
| jq -e 'map(gsub("^utils$";   "cpp"))'                    \
| jq -e 'map(gsub("^cmake$";   "cpp"))'                    \
| jq -e 'map(gsub("^ninja$";   "cpp"))'                    \
| jq -e 'map(gsub("^sccache$"; "cpp"))'                    \
| jq -e -r 'unique | join("|")'                            \
|| echo ''                                                 \
)";

if [[ -n "$changed_features" ]]; then
  changed_features="$(            \
    cat images/matrix.yml         \
  | grep -E "($changed_features)" \
  | yq -e -o json --no-colors     \
  | jq -ceM                       \
 || echo ''
  )";
fi

if [[ "$changed_images" == "null" ]]; then changed_images=""; fi
if [[ "$changed_features" == "null" ]]; then changed_features=""; fi

# Concatenate changed feature/image lists and write the matrix
cat <<EOF
matrix={"include":$(echo        \
  "$changed_images"             \
  "$changed_features"           \
| jq -scM 'flatten(1) | unique' \
)}
EOF
