#!/usr/bin/env bash

# Usage:
#  uninstall-all [OPTION]...
#
# Runs uninstall-<repo> for each repo in "${NAMES}".
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help,--usage                      print this text
#  -v,--verbose                           verbose output

uninstall_all() {
    local -;
    set -Eeuo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"uninstall-all"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    for name in ${NAMES}; do
        if type uninstall-${name} >/dev/null 2>&1; then
            uninstall-${name} "$@";
        fi
    done
}

uninstall_all "$@";
