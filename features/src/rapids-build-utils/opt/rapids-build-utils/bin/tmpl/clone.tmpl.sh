#! /usr/bin/env bash

clone_${NAME}() {
    set -euo pipefail;

    if [[ ! -d ~/"${SRC_PATH}"/.git ]]; then

        local branch=;
        local upstream=;
        local directory=;
        local no_fork=;
        local clone_upstream=;
        local no_update_env=;

        eval "$(                                  \
            devcontainer-utils-parse-args --names '
                b|branch                          |
                d|directory                       |
                u|upstream                        |
                no-fork                           |
                clone-upstream                    |
                no-update-env                     |
            ' - <<< "$@"                          \
          | xargs -r -d'\n' -I% echo -n local %\; \
        )";

        branch="${b:-${branch:-"${GIT_TAG}"}}";
        directory="${d:-${directory:-"${HOME}/${SRC_PATH}"}}";
        upstream="${u:-${upstream:-"${GIT_UPSTREAM}/${GIT_REPO}"}}";

        echo 'Cloning ${NAME}' 1>&2;

        devcontainer-utils-clone-${GIT_HOST}-repo \
            --tags                                \
            --branch "${branch}"                  \
            --recurse-submodules                  \
            -j $(nproc --ignore=2)                \
            -c checkout.defaultRemote=upstream    \
            ${no_fork:+--no-fork 1}               \
            ${clone_upstream:+--clone-upstream 1} \
            ${__rest__[@]}                        \
            "${upstream}"                         \
            "${directory}"                        \
        ;

        git -C ~/"${SRC_PATH}" config --add remote.upstream.fetch '^refs/heads/pull-request/*';

        local upstream_branches="$(git -C ~/"${SRC_PATH}" branch --remotes --list 'upstream/pull-request/*')";
        if test -n "${upstream_branches:-}"; then
            git -C ~/"${SRC_PATH}" branch --remotes -d ${upstream_branches};
        fi

        git -C ~/"${SRC_PATH}" remote prune upstream;

        if test -z "${no_update_env:-}"; then
            rapids-update-content-command;
            rapids-post-attach-command;
        fi
    fi
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clone_${NAME} "$@";
