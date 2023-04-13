#! /usr/bin/env bash

clone_${NAME}() {
    set -euo pipefail;

    if [[ ! -d ~/'${SRC_PATH}/.git' ]]; then

        local git_tag='${GIT_TAG}';
        local git_args="${@}";
        if ! echo "${git_args}" | grep -qE '(\-b |\-b=|\-\-branch |\-\-branch=)'; then
            git_args="${git_args:+"$git_args "}${git_tag:+"--branch $git_tag"}";
        fi

        echo 'Cloning ${NAME}' 1>&2;

        devcontainer-utils-clone-${GIT_HOST}-repo \
            '${GIT_UPSTREAM}'                     \
            '${GIT_REPO}'                         \
            '${SRC_PATH}'                         \
             ${git_args}                          \
            ;

        rapids-generate-scripts;

        rapids-make-vscode-workspace --update;
    fi
}

(clone_${NAME} "$@");
