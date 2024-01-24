#!/usr/bin/env bash

# Usage:
#  install-${NAME} [OPTION]...
#
# Install ${CPP_LIB} and ${PY_LIB}.
#
# Boolean options:
#  -h,--help,--usage  print this text
#  -v,--verbose       verbose output
#  --strip                      Strip before installing.
#
# Options that require values:
#  -p,--prefix <dir>                            Install C++ library into <dir>
#                                               (default: none)
#  --config    <cfg>                            For multi-configuration generators, choose configuration <cfg>
#                                               (default: none)
#  --component <comp>                           Component-based install. Only install component <comp>.
#                                               (default: all)
#  --default-directory-permissions <permission> Default install permission. Use default permission <permission>.

. devcontainer-utils-parse-args-from-docstring;

install_${NAME}() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    for lib in ${CPP_LIB}; do
        if type install-${lib}-cpp >/dev/null 2>&1; then
            install-${lib}-cpp "$@";
        fi
    done
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"install-${NAME}"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

install_${NAME} "$@";