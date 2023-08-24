#! /usr/bin/env bash

list_repos() {
    set -euo pipefail;

    local repo=;
    local manifest=;

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            r|repo                            |
            m|manifest                        |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    repo="${r:-${repo:-}}";
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
        | map(select(.key | startswith("repos")))
        | map(.key + "=" + (.val | @sh | gsub("[\\n]"; " ")))[]
________EOF
)";

    if test -n "${repo:-}"; then
        query="$(cat <<________EOF | tr -s '[:space:]'
        .repos
        | map(select(.name == "${repo}"))
        | {repos: .}
        | ${query}
________EOF
)";
    fi

    yq -Mo json "${manifest}" | jq -r "${query}";
}

if test -n "${devcontainer_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(list_repos "$@");
