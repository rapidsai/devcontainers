#! /usr/bin/env bash

build_${CPP_LIB}_cpp() {

    set -euo pipefail;

    if [[ ! -d ~/${CPP_SRC} ]]; then
        exit 1;
    fi

    local verbose="";

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            v|verbose                         |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    verbose="${v:-${verbose:-}}";

    if test -n "${verbose}"; then verbose="--log-level=VERBOSE"; fi

    configure-${CPP_LIB}-cpp ${verbose} ${__rest__[@]};

    eval "$(                                     \
        rapids-get-jobs-and-archs ${__rest__[@]} \
      | xargs -r -d'\n' -I% echo -n local %\;    \
    )";

    if test -n "${verbose}"; then verbose="--verbose"; fi

    time                                        \
    JOBS="${n_jobs}" PARALLEL_LEVEL="${n_jobs}" \
    cmake --build ~/${CPP_SRC}/build/latest ${verbose} --parallel ${n_jobs};
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(build_${CPP_LIB}_cpp "$@");
