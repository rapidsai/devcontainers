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

. devcontainer-utils-parse-args-from-docstring;

cpack_${CPP_LIB}_cpp() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    local verbose="${v:-${verbose:-}}";
    local out_dir="${o:-${out_dir:-}}";

    time (
        (
            cd "${CPP_SRC}"/build/latest/;
            cpack -G TGZ ${verbose:+-V};
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

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"cpack-${CPP_LIB}-cpp"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

cpack_${CPP_LIB}_cpp "$@";
