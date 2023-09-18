#! /usr/bin/env bash

build_${PY_LIB}_python_dist() {

    # pull out the --rapids-dist or --rapids-inplace args (if any)
    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            rapids-dist                       |
            rapids-inplace                    |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    # check if rapids_dist is set.

    if [[ ! -z ${rapids_dist+x} ]]; then
        build-${PY_LIB}-python-dist ${__rest__[@]};
    else
        build-${PY_LIB}-python-inplace ${__rest__[@]};
    fi
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

build_${PY_LIB}_python_dist "$@";
