#! /usr/bin/env bash

clone_${NAME}() {
    set -euo pipefail;

    # PS4='+ ${LINENO}: '; set -x;

    if [[ ! -d ~/"${SRC_PATH}"/.git ]]; then

        local branch=;

        eval "$(                                  \
            devcontainer-utils-parse-args         \
                --names 'b|branch' "$@"           \
          | xargs -r -d'\n' -I% echo -n local %\; \
          # | cat - <(echo 'set -- ${__rest__[@]}') \
        )";

        echo 'Cloning ${NAME}' 1>&2;

        __rest__+=(--tags);
        __rest__+=(--recurse-submodules);
        __rest__+=(-j $(nproc --ignore=2));
        __rest__+=(-c checkout.defaultRemote=upstream);

        devcontainer-utils-clone-${GIT_HOST}-repo ${__rest__[@]} \
            --branch "${b:-${branch:-"${GIT_TAG}"}}" \
            "${GIT_UPSTREAM}/${GIT_REPO}" \
            ~/"${SRC_PATH}";

        git -C ~/"${SRC_PATH}" config --add remote.upstream.fetch '^refs/heads/pull-request/*';
        git -C ~/"${SRC_PATH}" branch --remotes -d \
            $(git -C ~/"${SRC_PATH}" branch --remotes --list 'upstream/pull-request/*');
        git -C ~/"${SRC_PATH}" remote prune upstream;

        rapids-generate-scripts;

        rapids-make-vscode-workspace --update;
    fi
}

(clone_${NAME} "$@");
