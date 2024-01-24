#!/usr/bin/env bash

# Usage:
#  install-all [OPTION]...
#
# Runs install-<repo> for each repo in "${NAMES}".
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help,--usage                      print this text
#  -v,--verbose                           verbose output
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

install_all() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    for name in ${NAMES}; do
        if type install-${name} >/dev/null 2>&1; then
            install-${name} "$@";
        fi
    done
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"install-all"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

install_all "$@";