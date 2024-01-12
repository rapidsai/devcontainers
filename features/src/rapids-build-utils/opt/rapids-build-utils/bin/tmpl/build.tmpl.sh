#! /usr/bin/env bash

build_${NAME}() {
    set -euo pipefail;

    local mode="editable";

    # pull out the --mode editable|wheel arg (if any)
    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            m|mode                            |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    mode="${m:-${mode:-"editable"}}";

    for lib in ${CPP_LIB}; do
        if type build-${lib}-cpp >/dev/null 2>&1; then
            build-${lib}-cpp ${__rest__[@]};
        fi
    done
    for lib in ${PY_LIB}; do
        if type build-${lib}-python >/dev/null 2>&1; then
            build-${lib}-python -m ${mode} ${__rest__[@]};
        fi
    done
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

build_${NAME} "$@";
