#!/usr/bin/env bash

# Usage:
#  clean-all-cpp [OPTION]...
#
# Runs clean-<repo> for each repo in ${NAMES}.
#
# Forwards relevant arguments to each underlying script.
#
# Boolean options:
#  -h,--help            Print this text.
#  -v,--verbose         Verbose output.
#
# Options that require values:
#  -j,--parallel <num>  Clean <num> repos in parallel

# shellcheck disable=SC1091
. rapids-generate-docstring;

_clean_all_cpp() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-h,--help' "$@" <&0)";

    eval "$(rapids-get-num-archs-jobs-and-load --archs 0 "$@")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'clean-all clean-all-cpp';

    echo ${NAMES} \
  | tr '[:space:]' '\0' \
  | xargs ${v:+-t} -r -0 -P${n_jobs} -I% bash -c \
  " if command -v clean-%-cpp >/dev/null 2>&1; then if ! clean-%-cpp ${OPTS[*]@Q} ${v[*]@Q}; then exit 255; fi; fi";
}

_clean_all_cpp "$@" <&0;
