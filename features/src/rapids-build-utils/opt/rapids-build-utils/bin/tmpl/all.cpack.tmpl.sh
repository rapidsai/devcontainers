#!/usr/bin/env bash

# Usage:
#  cpack-all [OPTION]...
#
# Runs cpack-<repo> for each repo in "${NAMES}".
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help,--usage                            print this text
#  -v,--verbose                                 verbose output
#
# Options that require values:
#  -j,--parallel <num>                          CPack <num> repos in parallel
#  --component <comp>                           Component-based install. Only install component <comp>.
#                                               (default: all)
#  --config    <cfg>                            For multi-configuration generators, choose configuration <cfg>
#                                               (default: none)
#  --default-directory-permissions <permission> Default install permission. Use default permission <permission>.
#  -o,--out-dir <dir>                           copy cpack'd TGZ file into <dir>
#                                               (default: none)

cpack_all() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"cpack-all"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" --passthrough '
        -v,--verbose
        --component
        --config
        --default-directory-permissions
        -o,--out-dir
    ' - <<< "${@@Q}")";

    eval "$(rapids-get-num-archs-jobs-and-load -a1 "$@")";

    echo "${NAMES}"                     \
  | tr '[:space:]' '\0'                 \
  | xargs -r -0 -P${n_jobs} -I% bash -c "
    if type cpack-% >/dev/null 2>&1; then
        cpack-% ${OPTS[*]} || exit 255;
    fi
    ";
}

cpack_all "$@";
