#! /usr/bin/env -S bash -euo pipefail

build_${CPP_LIB}_cpp() {

    configure-${CPP_LIB}-cpp "$@";

    cmake --build ~/${CPP_SRC}/build/latest      \
        -j${PARALLEL_LEVEL:-$(nproc --ignore=2)} \
    ;
}

build_${CPP_LIB}_cpp "$@";
