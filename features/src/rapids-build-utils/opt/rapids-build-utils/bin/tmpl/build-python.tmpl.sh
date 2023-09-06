#! /usr/bin/env bash

build_${NAME}_python() {
    set -euo pipefail;

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            rapids-wheel                      |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    for lib in ${PY_LIB}; do
        if [ ! -z ${rapids_wheel+x} ]; then # if --rapids-wheel was passed
            if type build-${lib}-python >/dev/null 2>&1; then
                build-${lib}-wheel "$@";
            fi
        else
            if type build-${lib}-python >/dev/null 2>&1; then
                build-${lib}-python "$@";
            fi
        fi
    done
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(build_${NAME}_python "$@");
