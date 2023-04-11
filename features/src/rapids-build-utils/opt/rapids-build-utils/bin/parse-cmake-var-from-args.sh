#! /usr/bin/env bash

parse_cmake_var_from_args() {
    set -euo pipefail;

    echo "$(                                                  \
        export $(rapids-parse-cmake-vars-from-args "${@:2}"); \
        echo "\$$1" | envsubst "\$$1";                        \
    )";
}

(parse_cmake_var_from_args "$@");
