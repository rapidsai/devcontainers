#! /usr/bin/env bash

clone_${NAME}() {
    set -euo pipefail;

    if [[ ! -d ~/"${SRC_PATH}"/.git ]]; then

        local branch=;

        eval "$(                                  \
            devcontainer-utils-parse-args --names '
                b|branch                          |
            ' - <<< "$@"                          \
          | xargs -r -d'\n' -I% echo -n local %\; \
        )";

        branch="${b:-${branch:-"${GIT_TAG}"}}";

        echo 'Cloning ${NAME}' 1>&2;

        __rest__+=(--tags);
        __rest__+=(--recurse-submodules);
        __rest__+=(-j $(nproc --ignore=2));
        __rest__+=(-c checkout.defaultRemote=upstream);

        devcontainer-utils-clone-${GIT_HOST}-repo \
            ${__rest__[@]} --branch "${branch}" \
            "${GIT_UPSTREAM}/${GIT_REPO}" \
            ~/"${SRC_PATH}";

        git -C ~/"${SRC_PATH}" config --add remote.upstream.fetch '^refs/heads/pull-request/*';

        local upstream_branches="$(git -C ~/"${SRC_PATH}" branch --remotes --list 'upstream/pull-request/*')";
        if test -n "${upstream_branches:-}"; then
            git -C ~/"${SRC_PATH}" branch --remotes -d ${upstream_branches};
        fi

        git -C ~/"${SRC_PATH}" remote prune upstream;

        rapids-update-content-command;
        rapids-post-attach-command;
    fi
}

if test -n "${devcontainer_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clone_${NAME} "$@";
