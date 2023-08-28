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

    eval "$(                                              \
        rapids-get-num-archs-jobs-and-load ${__rest__[@]} \
      | xargs -r -d'\n' -I% echo -n local %\;             \
    )";

    if test -n "${verbose}"; then verbose="--verbose"; fi

    time cmake                              \
        --build ~/${CPP_SRC}/build/latest   \
        ${verbose}                          \
        -j${n_jobs}                         \
        --                                  \
        -l${n_load};
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(build_${CPP_LIB}_cpp "$@");
