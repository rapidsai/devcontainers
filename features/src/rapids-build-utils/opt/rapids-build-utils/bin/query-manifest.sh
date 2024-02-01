#!/usr/bin/env bash

# Usage:
#  rapids-query-manifest [OPTION]... [QUERY]
#
# Query the `manifest.yaml` in a shell-friendly format.
#
# Boolean options:
#  -h,--help,--usage  print this text
#
# Options that require values:
#  -m,--manifest <file>  Use a specific manifest.json
#                        (default: ${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"})

query_manifest() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
          || test -z "${rapids_build_utils_debug##*"query-manifest"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

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

query_manifest "$@";
