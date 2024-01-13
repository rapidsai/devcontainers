#! /usr/bin/env bash

install_${CPP_LIB}_cpp() {

    set -Eeuo pipefail;

    local verbose="";

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            v|verbose                         |
            o|out-dir                         |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    verbose="${v:-${verbose:-}}";
    out_dir="${o:-${out_dir:-}}";

    time (
        (
            cd "${CPP_SRC}"/build/latest/;
            cpack -G TGZ ${verbose:+-V};
        ) || true;

        if test -d "${out_dir}"/; then
            find "${CPP_SRC}"/build/latest/ \
                -iname "${CPP_LIB}-*.tar.gz"  \
                -exec cp -a "{}" "${out_dir}"/;
        fi

        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} CPack time:";
    ) 2>&1;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

install_${CPP_LIB}_cpp "$@";
