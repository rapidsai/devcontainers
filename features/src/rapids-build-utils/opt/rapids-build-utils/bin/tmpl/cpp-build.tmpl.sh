#! /usr/bin/env bash

build_${CPP_LIB}_cpp() {

    set -euo pipefail;

    if [[ ! -d ~/${CPP_SRC} ]]; then
        exit 1;
    fi

    configure-${CPP_LIB}-cpp "$@";

    eval "$(                                  \
        rapids-get-jobs-and-archs "$@"        \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    time                                      \
    JOBS="${n_jobs}"                          \
    PARALLEL_LEVEL="${n_jobs}"                \
    cmake --build ~/${CPP_SRC}/build/latest   \
          --parallel ${n_jobs} \
          --verbose;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(build_${CPP_LIB}_cpp "$@");
