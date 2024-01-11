#! /usr/bin/env bash

list_repos() {
    set -euo pipefail;

    local repo=;

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            r|repo                            |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    repo="${r:-${repo:-}}";

    local query=".repos | {repos: .}";

    if test -n "${repo:-}"; then
        query="$(cat <<________EOF | tr -s '[:space:]'
        .repos
        | map(select(.name == "${repo}"))
        | {repos: .}
________EOF
)";
    fi

    rapids-query-manifest ${__rest__[@]} "${query}";
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(list_repos "$@");
