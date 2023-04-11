#! /usr/bin/env bash

parse_cmake_vars_from_args() {
    set -euo pipefail;

    local args="";
    args="$(rapids-parse-cmake-args "$@")";
    args="$(rapids-join-strings "\n" $args)";
    echo -e "$args" \
  | grep '\-D' \
  | sed -r 's/^-D//' \
  | xargs -d'\n' -I{} echo -n "{} ";
}

(parse_cmake_vars_from_args "$@");
