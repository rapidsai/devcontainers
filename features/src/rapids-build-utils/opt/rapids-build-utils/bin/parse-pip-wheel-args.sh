#!/usr/bin/env bash

# Usage:
#  rapids-parse-pip-wheel-args [OPTION]...
#
# Filter an arguments list to the subset that `pip wheel` accepts.
#
# -q,--quiet   <value> Give less output. Option is additive, and can be used up to 3 times (corresponding to WARNING, ERROR, and CRITICAL logging levels).
# -v,--verbose <value> Give more output. Option is additive, and can be used up to 3 times.
# Wheel Options:

if ! test -f /tmp/pip-wheel-help.txt; then
    pip wheel --help >/tmp/pip-wheel-help.txt 2>&1;
fi

# shellcheck disable=SC1091
. devcontainer-utils-parse-args-from-docstring;

parse_pip_wheel_args() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
          || test -z "${rapids_build_utils_debug##*"parse-args"*}" \
          || test -z "${rapids_build_utils_debug##*"parse-pip-wheel-args"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args <(
        cat <(print_usage rapids-parse-pip-wheel-args) \
            <(sed -n '0,/Wheel Options:/!p' /tmp/pip-wheel-help.txt) \
      | sed 's/^/# /'
    ) "$@" <&0)";

    echo "${ARGS[*]}";
}

parse_pip_wheel_args "$@" <&0;
