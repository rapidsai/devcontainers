#!/usr/bin/env bash

parse_valid_args() {

    set -euo pipefail;

    local cmd="$@";
    local hash="$(echo "$cmd" | tr -d'[:space:]')";
    local file=${TMPDIR:-/tmp}/${hash}-args.log;

    if [[ ! -f ${file} ]]; then
        $cmd --help                             \
      | grep -oE '^  -(-|\w+|\d+|, --|, |,|=)+' \
      | tr -d '  ' | tr ',' '\n'                \
      | sed -r '/^\s*$/d'                       \
      > ${file};
    fi

    cat ${file};
}

(parse_valid_args "$@");
