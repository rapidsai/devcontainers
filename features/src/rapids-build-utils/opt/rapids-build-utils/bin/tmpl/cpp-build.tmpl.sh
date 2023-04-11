#! /usr/bin/env bash

build_${CPP_LIB}_cpp() {

    set -euo pipefail;

    configure-${CPP_LIB}-cpp "$@";

    cmake --build ~/${CPP_SRC}/build/latest      \
        -j${PARALLEL_LEVEL:-$(nproc --ignore=2)} \
    ;
}

(build_${CPP_LIB}_cpp "$@");
