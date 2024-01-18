#!/usr/bin/env bash

parse_cmake_args() {

    set -euo pipefail;

    local ARG="";
    local args=(-GNinja);
    args+=(${CMAKE_ARGS:-});

    while test -n "${1:-}"; do
        ARG="${1:-}";
        if [[ "$ARG" == -D ]]; then
            shift;
            if test -n "${1:-}"; then
                ARG+="${1:-}";
                args+=("$ARG");
            fi
            shift;
            continue;
        fi
        shift;
        args+=("$(printf %q "${ARG}")");
    done;

    echo ${args[@]};
}

(parse_cmake_args "$@");
