#!/usr/bin/env bash

# Usage:
#  clone-${NAME} [OPTION]...
#
# Clone the ${NAME} repository if it doesn't already exist.
#
# Boolean options:
# @_include_bool_options /usr/bin/devcontainer-utils-clone-github-repo -h | tail -n+2 | head -n-1;
#  --no-update-env              Don't update the Python env with the repo's dependencies after cloning.
#                               (default: false)
#
# Options that require values:
# @_include_value_options /usr/bin/devcontainer-utils-clone-github-repo -h | tail -n+2 | head -n-1;
#  -d,--directory <dir>         Clone the repo into <dir>.
#                               (default: `${NAME}.path` in manifest.yaml)
#  -u,--upstream <upstream>     Set <upstream> as the `upstream` remote.
#                               (default: `${NAME}.git.upstream` in manifest.yaml)

# shellcheck disable=SC1091
. rapids-generate-docstring;

clone_${NAME}() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '
        --no-update-env
        -b,--branch
        -d,--directory
        -u,--upstream
    ' "$@" <&0)";

    eval "$(rapids-get-num-archs-jobs-and-load --archs 0 "$@")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'clone-all clone-${NAME}';

    branch="${b:-"${GIT_TAG}"}";
    directory="${d:-"${SRC_PATH}"}";
    ssh_url="${ssh_url:-${GIT_SSH_URL}}";
    https_url="${https_url:-${GIT_HTTPS_URL}}";
    upstream="${u:-"${GIT_UPSTREAM}/${GIT_REPO}"}";

    echo 'Cloning ${NAME}' 1>&2;

    devcontainer-utils-clone-${GIT_HOST}-repo   \
        --tags                                  \
        --branch "${branch}"                    \
        --ssh-url "${ssh_url}"                  \
        --https-url "${https_url}"              \
        --recurse-submodules                    \
        -j ${n_jobs:-$(nproc --all --ignore=1)} \
        -c checkout.defaultRemote=upstream      \
        "${OPTS[@]}"                            \
        --                                      \
        "${upstream}"                           \
        "${directory}"                          \
    ;

    git -C "${SRC_PATH}" config --add remote.upstream.fetch '^refs/heads/pull-request/*';

    local upstream_branches="$(git -C "${SRC_PATH}" branch --remotes --list 'upstream/pull-request/*')";
    if test -n "${upstream_branches:-}"; then
        git -C "${SRC_PATH}" branch --remotes -d ${upstream_branches};
    fi

    git -C "${SRC_PATH}" remote prune upstream;

    if test -z "${no_update_env-}"; then
        rapids-post-start-command;
    fi
}

clone_${NAME} "$@" <&0;
