#!/usr/bin/env bash

# Usage:
#  clone-all [OPTION]...
#
# Runs clone-<repo> for each repo in ${NAMES}.
#
# Boolean options:
# @_include_bool_options /usr/bin/devcontainer-utils-clone-github-repo -h | tail -n+2 | head -n-1;
#  --no-update-env              Don't update the Python env with the repo's dependencies after cloning.
#                               (default: false)
#
# Options that require values:
#  -j,--parallel <num>          Clone <num> repos in parallel.
#                               (default: 1)

# shellcheck disable=SC1091
. rapids-generate-docstring;

clone_all() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-j,--parallel --no-update-env' "$@" <&0)";

    eval "$(rapids-get-num-archs-jobs-and-load --archs 3 "$@")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'clone-all';

    echo ${NAMES} \
  | tr '[:space:]' '\0' \
  | xargs ${v:+-t} -r -0 -P${n_jobs} -I% bash -c "
    if type clone-% >/dev/null 2>&1; then
        clone-% -j ${n_arch} --no-update-env ${OPTS[*]} || exit 255;
    fi
    ";

    if test -z "${no_update_env-}"; then
        rapids-update-content-command;
        rapids-post-attach-command;
    fi
}

clone_all "$@" <&0;
