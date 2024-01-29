#!/usr/bin/env bash

# Usage:
#  clone-all [OPTION]...
#
# Runs clone-<repo> for each repo in "${NAMES}".
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
#  -j,--parallel <num>          Clone <num> repos in parallel
#                               (default: 1)

clone_all() {
    set -Eeuo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" --passthrough '
        --no-fork
        --clone-upstream
    ' - <<< "${@@Q}")";

    eval "$(rapids-get-num-archs-jobs-and-load -a1 "$@")";

    local -r n_repos=$(wc -w <<< "${NAMES}");
    n_jobs=$((n_repos < n_jobs ? n_repos : n_jobs));

    local n_modules=$((n_jobs / n_repos));
    n_modules=$((n_modules < 1 ? 1 : n_modules));

    echo "${NAMES}"                     \
  | tr '[:space:]' '\0'                 \
  | xargs -r -0 -P${n_jobs} -I% bash -c "
    if type clone-% >/dev/null 2>&1; then
        clone-% -j ${n_modules} --no-update-env ${OPTS[*]} || exit 255;
    fi
    ";

    if test -z "${no_update_env-}"; then
        rapids-update-content-command;
        rapids-post-attach-command;
    fi
}

if test -n "${rapids_build_utils_debug:-}" \
&& { test -z "${rapids_build_utils_debug##*"*"*}" \
  || test -z "${rapids_build_utils_debug##*"clone-all"*}"; }; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clone_all "$@";
