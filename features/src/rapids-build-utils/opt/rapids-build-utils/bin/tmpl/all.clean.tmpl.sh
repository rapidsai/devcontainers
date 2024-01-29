#!/usr/bin/env bash

# Usage:
#  clean-all [OPTION]...
#
# Runs clean-<repo> for each repo in "${NAMES}".
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help,--usage                      print this text
#
# Options that require values:
#  -j,--parallel <num>          Clone <num> repos in parallel

clean_all() {
    local -;
    set -Eeuo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"clean-all"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    eval "$(rapids-get-num-archs-jobs-and-load -a1 "$@")";

    echo "${NAMES}"                     \
  | tr '[:space:]' '\0'                 \
  | xargs -r -0 -P${n_jobs} -I% bash -c "
    if type clean-% >/dev/null 2>&1; then
        clean-% $* || exit 255;
    fi
    ";
}

clean_all "$@";
