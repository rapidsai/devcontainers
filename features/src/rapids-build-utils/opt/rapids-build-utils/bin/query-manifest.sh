#!/usr/bin/env bash

# Usage:
#  rapids-query-manifest [OPTION]... [QUERY]
#
# Query the `manifest.yaml` in a shell-friendly format.
#
# Boolean options:
#  -h,--help             Print this text.
#
# Options that require values:
#  -m,--manifest <file>  Use a specific manifest.json.
#                        (default: ${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"})

# shellcheck disable=SC1091
. rapids-generate-docstring;

query_manifest() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args "$@" <&0)";

    if test "${REST[0]:-}" == --; then REST=("${REST[@]:1}"); fi;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'query-manifest';

    local manifest="${m:-${manifest:-"${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"}"}}";

    local query=;

    query="$(cat <<"________EOF" | tr -s '[:space:]'
        [
          paths(arrays) as $path | {
            "key": ($path + ["length"]) | join("_"),
            "val": getpath($path) | length
          }
        ] + [
          paths(scalars) as $path | {
            "key": $path | join("_"),
            "val": getpath($path)
          }
        ]
        | map(select(.key))
        | map("declare " + .key + "=" + (.val | @sh | gsub("[\\n]"; " ")))[]
________EOF
)";

    query="$(cat <<________EOF | tr -s '[:space:]'
        ${REST[@]}
        | ${query}
________EOF
)";

    yq -Mo json "${manifest}" | jq -r "${query}";
}

query_manifest "$@" <&0;
