#! /usr/bin/env bash

build_${CPP_LIB}_cpp() {

    set -euo pipefail;

    configure-${CPP_LIB}-cpp "$@";

    eval "$(                                  \
        rapids-get-jobs-and-archs "$@"        \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    JOBS=${n_jobs}                            \
    PARALLEL_LEVEL=${n_jobs}                  \
    NVCC_APPEND_FLAGS="--threads=${n_arch} ${NVCC_APPEND_FLAGS:-}" \
    cmake --build ~/${CPP_SRC}/build/latest   \
          --parallel ${n_jobs} \
          --verbose;
}

(build_${CPP_LIB}_cpp "$@");
