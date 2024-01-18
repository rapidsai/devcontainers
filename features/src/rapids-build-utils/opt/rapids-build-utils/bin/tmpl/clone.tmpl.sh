#!/usr/bin/env bash

# Usage:
#  clone-${NAME}-cpp [OPTION]...
#
# Clone the ${NAME} repository.
#
# Boolean options:
#  -h,--help,--usage            print this text
#  --no-fork                    don't prompt the user to fork the repo if a user fork isn't found
#                               (default: false)
#  --no-update-env              don't update the Python env with the repo's dependencies after cloning
#                               (default: false)
#  --clone-upstream             always clone the upstream, not the user's fork
#                               (default: false)
#
# Options that require values:
#  -b,--branch <branch_or_tag>  check the repo out to <branch_or_tag>
#                               (default: `${NAME}.git.tag` in manifest.yaml)
#  -d,--directory <dir>         clone the repo into <dir>
#                               (default: `${NAME}.path` in manifest.yaml)
#  -u,--upstream <upstream>     set <upstream> as the `upstream` remote
#                               (default: `${NAME}.git.upstream` in manifest.yaml)

. devcontainer-utils-parse-args-from-docstring;

clone_${NAME}() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    if [[ ! -d "${SRC_PATH}"/.git ]]; then

        local no_fork="${no_fork:-}";
        local no_update_env="${no_update_env:-}";
        local clone_upstream="${clone_upstream:-}";
        local branch="${b:-${branch:-"${GIT_TAG}"}}";
        local directory="${d:-${directory:-"${SRC_PATH}"}}";
        local upstream="${u:-${upstream:-"${GIT_UPSTREAM}/${GIT_REPO}"}}";

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

        git -C "${SRC_PATH}" config --add remote.upstream.fetch '^refs/heads/pull-request/*';

        local upstream_branches="$(git -C "${SRC_PATH}" branch --remotes --list 'upstream/pull-request/*')";
        if test -n "${upstream_branches:-}"; then
            git -C "${SRC_PATH}" branch --remotes -d ${upstream_branches};
        fi

        git -C "${SRC_PATH}" remote prune upstream;

        if test -z "${no_update_env:-}"; then
            rapids-update-content-command;
            rapids-post-attach-command;
        fi
    fi
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"clone-${NAME}"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clone_${NAME} "$@";
