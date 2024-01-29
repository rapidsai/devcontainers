#!/usr/bin/env bash

# Usage:
#  cpack-all [OPTION]...
#
# Runs cpack-<repo> for each repo in "${NAMES}".
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help,--usage            print this text
#
# Options that require values:
#  -j,--parallel <num>          Clone <num> repos in parallel
#  -o,--out-dir <dir>           copy cpack'd TGZ file into <dir>
#                               (default: none)

cpack_all() {
    set -Eeuo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    eval "$(rapids-get-num-archs-jobs-and-load -a1 "$@")";

    echo "${NAMES}"                     \
  | tr '[:space:]' '\0'                 \
  | xargs -r -0 -P${n_jobs} -I% bash -c "
    if type cpack-% >/dev/null 2>&1; then
        cpack-% $* || exit 255;
    fi
    ";
}

if test -n "${rapids_build_utils_debug:-}" \
&& { test -z "${rapids_build_utils_debug##*"*"*}" \
  || test -z "${rapids_build_utils_debug##*"cpack-all"*}"; }; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

cpack_all "$@";
