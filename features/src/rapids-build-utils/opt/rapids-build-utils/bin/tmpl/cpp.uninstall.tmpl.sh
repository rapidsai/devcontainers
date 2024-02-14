#!/usr/bin/env bash

# Usage:
#  uninstall-${CPP_LIB}-cpp [OPTION]...
#
# Uninstall ${CPP_LIB}.
#
# Boolean options:
#  -h,--help          print this text
#  -v,--verbose       verbose output

uninstall_${CPP_LIB}_cpp() {
    local -;
    set -euo pipefail;


    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";
    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'uninstall-all uninstall-${NAME} uninstall-${CPP_LIB}-cpp';

    if test -f "${CPP_SRC}/${BIN_DIR}/install_manifest.txt"; then
        time (
            xargs ${v:+-t} -rd "\n" --arg-file=<(<"${CPP_SRC}/${BIN_DIR}/install_manifest.txt" tr -d "\r") rm -f ${v:+-v} --;
        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} uninstall time:";
    ) 2>&1;
    fi
}

uninstall_${CPP_LIB}_cpp "$@";
