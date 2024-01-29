#!/usr/bin/env bash

parse_valid_args() {
    local -;
    set -Eeuo pipefail;

    local -r cmd="$*";
    local -r hash="$(echo "$cmd" | tr -d'[:space:]')";
    local -r file="${TMPDIR:-/tmp}/${hash}-args.log";

    if [[ ! -f "${file}" ]]; then
        $cmd --help                             \
      | grep -oE '^  -(-|\w+|\d+|, --|, |,|=)+' \
      | tr -d '  ' | tr ',' '\n'                \
      | sed -r '/^\s*$/d'                       \
      > "${file}";
    fi

    cat "${file}";
}

parse_valid_args "$@";
