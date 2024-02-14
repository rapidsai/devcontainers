#!/usr/bin/env bash

# Usage:
#  cpack-all [OPTION]...
#
# Runs cpack-<repo> for each repo in ${NAMES}.
#
# Forwards relevant arguments to each underlying script.
#
# Boolean options:
#  -h,--help                                     Print this text.
# @_include_bool_options rapids-select-cmake-install-args -h | tail -n-3 | head -n-1;
#
# Options that require values:
#  -j,--parallel <num>                           CPack <num> repos in parallel.
#                                                (default: 1)
#  -o,--out-dir <dir>                            Copy cpack'd TGZ file into <dir>.
#                                                (default: none)
# @_include_value_options rapids-select-cmake-install-args -h | tail -n-5 | head -n-2;

# shellcheck disable=SC1091
. rapids-generate-docstring;

cpack_all() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-j,--parallel' "$@" <&0)";

    j=${j:-1};

    local -r n_repos=$(echo ${NAMES} | wc -w);
    local k=$((n_repos / j));

    eval "$(rapids-get-num-archs-jobs-and-load -j "${j}" -a "${k}" --max-archs "${k}")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'cpack-all';

    echo ${NAMES} \
  | tr '[:space:]' '\0' \
  | xargs -r -0 -P${n_load} -I% bash -c "
    if type cpack-% >/dev/null 2>&1; then
        cpack-% -j ${n_arch} ${OPTS[*]} || exit 255;
    fi
    ";
}

cpack_all "$@" <&0;
