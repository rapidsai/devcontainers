#!/usr/bin/env bash

# Usage:
#  cpack-${CPP_LIB}-cpp [OPTION]...
#
# CPack ${CPP_LIB}.
#
# Boolean options:
#  -h,--help,--usage            print this text
#  -v,--verbose                 verbose output
#
# Options that require values:
#  -o,--out-dir <dir>           copy cpack'd TGZ file into <dir>
#                               (default: none)

cpack_${CPP_LIB}_cpp() {
    local -;
    set -Eeuo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"cpack-all"*}" \
      || test -z "${rapids_build_utils_debug##*"cpack-${CPP_LIB}-cpp"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    time (
        (
            cd "${CPP_SRC}"/build/latest/;
            cpack -G TGZ ${v:+-V};
        ) || true;

        if test -d "${out_dir}"/; then
            find "${CPP_SRC}"/build/latest/     \
                -iname "${CPP_LIB}-*.tar.gz"    \
                -print0                         \
          | xargs -0 -I% cp -a "%" "${out_dir}"/;
        fi

        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} CPack time:";
    ) 2>&1;
}

cpack_${CPP_LIB}_cpp "$@";
