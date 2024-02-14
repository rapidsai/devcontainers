#!/usr/bin/env bash

# Usage:
#  uninstall-${PY_LIB}-python [OPTION]...
#
# Uninstall ${PY_LIB}.
#
# Boolean options:
#  -h,--help         print this text
#  -v,--verbose      verbose output

uninstall_${PY_LIB}_python() {
    local -;
    set -euo pipefail;


    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";
    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'uninstall-all uninstall-${NAME} uninstall-${PY_LIB}-python';

    if [[ ! -d "${PY_SRC}" ]]; then
        exit 1;
    fi

    time (
        pip uninstall -y ${v:+-vv} "${PY_LIB}";
        { set +x; } 2>/dev/null; echo -n "${PY_LIB} uninstall time:";
    ) 2>&1;

}

uninstall_${PY_LIB}_python "$@";
