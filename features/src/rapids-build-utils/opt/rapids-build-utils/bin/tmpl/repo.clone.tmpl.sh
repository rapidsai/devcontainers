#!/usr/bin/env bash

# Usage:
#  clone-${NAME} [OPTION]...
#
# Clone the ${NAME} repository if it doesn't already exist.
#
# Boolean options:
#  -h,--help                    print this text
#  -q,--quiet                   Operate quietly. Progress is not reported to the standard error stream.
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
#  -j,--parallel <num>          Clone <num> submodules in parallel
#                               (default: $(nproc --ignore=1))
#  -u,--upstream <upstream>     set <upstream> as the `upstream` remote
#                               (default: `${NAME}.git.upstream` in manifest.yaml)

clone_${NAME}() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"clone-all"*}" \
      || test -z "${rapids_build_utils_debug##*"clone-${NAME}"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" --skip '
        -q,--quiet
        --no-fork
        --clone-upstream
    ' - <<< "${@@Q}")";

    if [[ ! -d "${SRC_PATH}"/.git ]]; then

        eval "$(rapids-get-num-archs-jobs-and-load "$@")";

        branch="${b:-"${GIT_TAG}"}";
        directory="${d:-"${SRC_PATH}"}";
        upstream="${u:-"${GIT_UPSTREAM}/${GIT_REPO}"}";

        echo 'Cloning ${NAME}' 1>&2;

        devcontainer-utils-clone-${GIT_HOST}-repo                 \
            --tags                                                \
            --branch "${branch}"                                  \
            --recurse-submodules                                  \
            -j ${n_jobs:-$(nproc --ignore=1)}                     \
            -c checkout.defaultRemote=upstream                    \
            -c remote.upstream.fetch='^refs/heads/pull-request/*' \
            "${OPTS[@]}"                                          \
            --                                                    \
            "${upstream}"                                         \
            "${directory}"                                        \
        ;

        if test -z "${no_update_env}"; then
            rapids-update-content-command;
            rapids-post-attach-command;
        fi
    fi
}

clone_${NAME} "$@";
