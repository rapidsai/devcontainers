#! /usr/bin/env bash

clean_${CPP_LIB}_cpp() {

    set -euo pipefail;

    rm -rf ~/${CPP_SRC}/build/latest/*;
}

(clean_${CPP_LIB}_cpp "$@");
