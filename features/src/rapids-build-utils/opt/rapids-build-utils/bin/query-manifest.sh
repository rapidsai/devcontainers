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

. devcontainer-utils-parse-args-from-docstring;

query_manifest() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "${@@Q}";

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
        | map(.key + "=" + (.val | @sh | gsub("[\\n]"; " ")))[]
________EOF
)";

    query="$(cat <<________EOF | tr -s '[:space:]'
        ${__rest__[-1]}
        | ${query}
________EOF
)";

    yq -Mo json "${manifest}" | jq -r "${query}";
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"query-manifest"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(query_manifest "$@");
