#! /usr/bin/env -S bash -euo pipefail

join_with_delimiter() {
    local IFS='' delim=$1;
    shift;
    echo -n "$1";
    shift;
    echo -n "${*/#/$delim}";
}

join_with_delimiter "$@";
