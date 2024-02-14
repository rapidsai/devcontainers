#!/usr/bin/env bash

# Usage:
#  cpack-all [OPTION]...
#
# Runs cpack-<repo> for each repo in "${NAMES}".
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help                                    print this text
#  -v,--verbose                                 verbose output
#  --strip                                      Strip before installing.
#
# Options that require values:
#  -j,--parallel <num>                          CPack <num> repos in parallel
#                                               (default: 1)
#  --component <comp>                           Component-based install. Only install component <comp>.
#                                               (default: all)
#  --config    <cfg>                            For multi-configuration generators, choose configuration <cfg>
#                                               (default: none)
#  --default-directory-permissions <permission> Default install permission. Use default permission <permission>.
#  -o,--out-dir <dir>                           copy cpack'd TGZ file into <dir>
#                                               (default: none)

cpack_all() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" --skip '
        -v,--verbose
        --component
        --config
        --default-directory-permissions
        -o,--out-dir
    ' - <<< "${@@Q}")";

    j=${j:-1};
    local -r n_repos=$(wc -w <<< "${NAMES}");
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

cpack_all "$@";
