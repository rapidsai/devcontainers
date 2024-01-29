#!/usr/bin/env bash

# Usage:
#  uninstall-${PY_LIB}-python [OPTION]...
#
# Uninstall ${PY_LIB}.
#
# Boolean options:
#  -h,--help,--usage print this text
#  -v,--verbose      verbose output

uninstall_${PY_LIB}_python() {
    set -Eeuo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    if [[ ! -d "${PY_SRC}" ]]; then
        exit 1;
    fi

    time (
        pip uninstall -y ${v:+-vv} "${PY_LIB}";
        { set +x; } 2>/dev/null; echo -n "${PY_LIB} uninstall time:";
    ) 2>&1;

}

if test -n "${rapids_build_utils_debug:-}" \
&& { test -z "${rapids_build_utils_debug##*"*"*}" \
  || test -z "${rapids_build_utils_debug##*"uninstall-all"*}" \
  || test -z "${rapids_build_utils_debug##*"uninstall-${PY_LIB}-python"*}"; }; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

uninstall_${PY_LIB}_python "$@";
