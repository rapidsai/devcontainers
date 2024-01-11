#! /usr/bin/env bash

query_manifest() {
    set -euo pipefail;

    local manifest=;

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            m|manifest                        |
        ' - <<< "${@@Q}"                      \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    manifest="${m:-${manifest:-"${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"}"}}";

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
        ${__rest__[@]}
        | ${query}
________EOF
)";

    yq -Mo json "${manifest}" | jq -r "${query}";
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(query_manifest "$@");
