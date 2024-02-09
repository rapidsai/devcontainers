#!/usr/bin/env bash

# Usage:
#  rapids-parse-pip-install-args [OPTION]...
#
# Filter an arguments list to the subset that `pip install` accepts.
#
# -q,--quiet   <value> Give less output. Option is additive, and can be used up to 3 times (corresponding to WARNING, ERROR, and CRITICAL logging levels).
# -v,--verbose <value> Give more output. Option is additive, and can be used up to 3 times.
# Install Options:

if ! test -f /tmp/pip-install-help.txt; then
    pip install --help >/tmp/pip-install-help.txt 2>&1;
fi

# shellcheck disable=SC1091
. devcontainer-utils-parse-args-from-docstring;

parse_pip_install_args() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
          || test -z "${rapids_build_utils_debug##*"parse-args"*}" \
          || test -z "${rapids_build_utils_debug##*"parse-pip-install-args"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args <(
        cat <(print_usage rapids-parse-pip-install-args) \
            <(sed -n '0,/Install Options:/!p' /tmp/pip-install-help.txt) \
      | sed 's/^/# /'
    ) "$@" <&0)";

    echo "${ARGS[*]}";
}

parse_pip_install_args "$@" <&0;
