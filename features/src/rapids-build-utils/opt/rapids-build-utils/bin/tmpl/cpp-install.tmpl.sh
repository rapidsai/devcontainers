#!/usr/bin/env bash

# Usage:
#  install-${CPP_LIB}-cpp [OPTION]...
#
# Install ${CPP_LIB}.
#
# Boolean options:
#  -h,--help,--usage            print this text
#  -v,--verbose                 verbose output
#
# Options that require values:
#  -p,--prefix <dir>            install C++ library into <dir>
#                               (default: none)

. devcontainer-utils-parse-args-from-docstring;

install_${CPP_LIB}_cpp() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    time (
        cmake --install "${CPP_SRC}"/build/latest/ "$@";
        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} install time:";
    ) 2>&1;
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"install-${CPP_LIB}-cpp"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

install_${CPP_LIB}_cpp "$@";
