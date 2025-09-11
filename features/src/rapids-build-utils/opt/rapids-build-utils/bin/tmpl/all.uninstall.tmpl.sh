#!/usr/bin/env bash

# Usage:
#  uninstall-all [OPTION]...
#
# Runs uninstall-<repo> for each repo in ${NAMES}.
#
# Forwards relevant arguments to each underlying script.
#
# Boolean options:
#  -h,--help     Print this text.
#  -q,--quiet    Less output. Option is additive, and can be
#                used up to 3 times (corresponding to WARNING,
#                ERROR, and CRITICAL logging levels).
#  -v,--verbose  Give more output. Option is additive, and can be
#                used up to 3 times.
#
# Options that require values:
#  -j,--parallel <num>  Uninstall <num> repos in parallel.

# shellcheck disable=SC1091
. rapids-generate-docstring;

uninstall_all() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help -j,--parallel -v,--verbose' "$@" <&0)";

    eval "$(rapids-get-num-archs-jobs-and-load --archs 0 "$@")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'uninstall-all';

    echo ${NAMES} \
  | tr '[:space:]' '\0' \
  | xargs ${v:+-t} -r -0 -P${n_jobs} -I% bash -c \
  " if command -V uninstall-% >/dev/null 2>&1; then if ! uninstall-% ${OPTS[*]@Q} ${v[*]@Q}; then exit 255; fi; fi";
}

uninstall_all "$@" <&0;
