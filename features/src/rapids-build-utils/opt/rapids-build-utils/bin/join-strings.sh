#! /usr/bin/env bash

join_with_delimiter() {
    set -euo pipefail
    local IFS='' delim=${1:-};
    shift;
    echo -n "${1:-}";
    shift;
    echo -n "${*/#/$delim}";
}

(join_with_delimiter "$@");
