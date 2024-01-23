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

. devcontainer-utils-parse-args-from-docstring;

clone_all() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    eval "$(                                    \
        rapids-get-num-archs-jobs-and-load "$@" \
      | xargs -r -d'\n' -I% echo -n local %\;   \
    )";

    local all_cpus=$(nproc);
    local n_repos=$(wc -w <<< "${NAMES}");
    n_jobs=$((n_repos < n_jobs ? n_repos : n_jobs));

    local n_modules=$((all_cpus / n_jobs));
    n_modules=$((n_modules < 1 ? 1 : n_modules));

    local clone_args=();
    clone_args+=(-j ${n_modules});
    clone_args+=(${no_fork:+"--no-fork"});
    clone_args+=(${no_update_env:+"--no-update-env"});
    clone_args+=(${clone_upstream:+"--clone-upstream"});

    echo "${NAMES}"                     \
  | tr '[:space:]' '\0'                 \
  | xargs -r -0 -P${n_jobs} -I% bash -c "
    if type clone-% >/dev/null 2>&1; then
        clone-% ${clone_args[*]};
    fi
    ";
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"clone-all"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clone_all "$@";
