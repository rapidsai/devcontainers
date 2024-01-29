#!/usr/bin/env bash

parse_cmake_var_from_args() {
    set -euo pipefail;

    eval "$(                                       \
        rapids-parse-cmake-vars-from-args "${@:2}" \
      | xargs -r -d'\n' -I% echo -n export %\;     \
    )";

    envsubst "\$$1" <<< "\$$1";
}

parse_cmake_var_from_args "$@";
