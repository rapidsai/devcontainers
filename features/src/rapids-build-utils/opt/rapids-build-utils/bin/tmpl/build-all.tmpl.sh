#! /usr/bin/env bash

build_all() {
    set -euo pipefail;
    build-all-inplace
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(build_all "$@");
