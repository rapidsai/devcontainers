#!/usr/bin/env bash

# Usage:
#  clean-all [OPTION]...
#
# Runs clean-<repo> for each repo in "${NAMES}".
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help                    print this text
#  -v,--verbose                 verbose output
#
# Options that require values:
#  -j,--parallel <num>          Clone <num> repos in parallel

clean_all() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" --skip '
        -v,--verbose
    ' - <<< "${@@Q}")";

    eval "$(rapids-get-num-archs-jobs-and-load -a1 "$@")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'clean-all';

    echo ${NAMES} \
  | tr '[:space:]' '\0' \
  | xargs ${v:+-t} -r -0 -P${n_jobs} -I% bash -c "
    if type clean-% >/dev/null 2>&1; then
        clean-% ${OPTS[*]} || exit 255;
    fi
    ";
}

clean_all "$@";
