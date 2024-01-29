#!/usr/bin/env bash

join_with_delimiter() {
    set -euo pipefail
    local IFS='' delim=${1:-};
    shift;
    echo -n "${1:-}";
    shift;
    echo -n "${*/#/$delim}";
}

parse_cmake_vars_from_args() {
    set -euo pipefail;

    local args="";
    args="$(rapids-parse-cmake-args "$@")";
    args="$(join_with_delimiter "\n" "${args}")";
    echo -e "$args" \
  | grep '\-D' \
  | sed -r 's/^-D//';
}

parse_cmake_vars_from_args "$@";
