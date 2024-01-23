#!/usr/bin/env bash

# Usage:
#  uninstall-${CPP_LIB}-cpp [OPTION]...
#
# Uninstall ${CPP_LIB}.
#
# Boolean options:
#  -h,--help,--usage            print this text
#  -v,--verbose                 verbose output
#

. devcontainer-utils-parse-args-from-docstring;

uninstall_${CPP_LIB}_cpp() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    local verbose="${v:-${verbose:-}}";

    if test -f "${CPP_SRC}"/build/latest/install_manifest.txt; then
        time (
            xargs ${verbose:+-t} -rd "\n" --arg-file=<(<"${CPP_SRC}"/build/latest/install_manifest.txt tr -d "\r") rm ${verbose:+-v} --;
        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} uninstall time:";
    ) 2>&1;
    fi
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"uninstall-${CPP_LIB}-cpp"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

uninstall_${CPP_LIB}_cpp "$@";
