#!/usr/bin/env bash

# Usage:
#  uninstall-${CPP_LIB}-cpp [OPTION]...
#
# Uninstall ${CPP_LIB}.
#
# Boolean options:
#  -h,--help,--usage  print this text
#  -v,--verbose       verbose output

uninstall_${CPP_LIB}_cpp() {
    set -Eeuo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    if test -f "${CPP_SRC}"/build/latest/install_manifest.txt; then
        time (
            xargs ${v:+-t} -rd "\n" --arg-file=<(<"${CPP_SRC}"/build/latest/install_manifest.txt tr -d "\r") rm -f ${v:+-v} --;
        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} uninstall time:";
    ) 2>&1;
    fi
}

if test -n "${rapids_build_utils_debug:-}" \
&& { test -z "${rapids_build_utils_debug##*"*"*}" \
  || test -z "${rapids_build_utils_debug##*"uninstall-all"*}" \
  || test -z "${rapids_build_utils_debug##*"uninstall-${CPP_LIB}-cpp"*}"; }; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

uninstall_${CPP_LIB}_cpp "$@";
