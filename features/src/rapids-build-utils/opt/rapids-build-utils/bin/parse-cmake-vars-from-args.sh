#!/usr/bin/env bash

join_with_delimiter() {
    local -;
    set -Eeuo pipefail
    local IFS='' delim=${1:-};
    shift;
    echo -n "${1:-}";
    shift;
    echo -n "${*/#/$delim}";
}

parse_cmake_vars_from_args() {
    local -;
    set -Eeuo pipefail;

    # shellcheck disable=SC2046
    echo -e "$(join_with_delimiter "\n" $(rapids-parse-cmake-args "$@"))" \
  | grep '\-D' \
  | sed -r 's/^-D//';
}

parse_cmake_vars_from_args "$@";
