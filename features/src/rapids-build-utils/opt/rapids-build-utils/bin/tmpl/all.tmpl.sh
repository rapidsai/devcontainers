#!/usr/bin/env bash

# Usage:
#  ${SCRIPT}-all [OPTION]...
#
# Runs the ${SCRIPT} in each ${NAMES}.
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help,--usage                      print this text
#  -v,--verbose                           verbose output

${SCRIPT}_all() {
    set -Eeuo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    for name in ${NAMES}; do
        if type ${SCRIPT}-${name} >/dev/null 2>&1; then
            ${SCRIPT}-${name} "$@";
        fi
    done
}

if test -n "${rapids_build_utils_debug:-}" \
&& { test -z "${rapids_build_utils_debug##*"*"*}" \
  || test -z "${rapids_build_utils_debug##*"${SCRIPT}-all"*}"; }; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

${SCRIPT}_all "$@";
