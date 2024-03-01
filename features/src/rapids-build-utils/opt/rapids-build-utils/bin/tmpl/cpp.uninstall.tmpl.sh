#!/usr/bin/env bash

# Usage:
#  uninstall-${CPP_LIB}-cpp [OPTION]...
#
# Uninstall ${CPP_LIB}.
#
# Boolean options:
#  -h,--help          Print this text.
#  -v,--verbose       Verbose output.
#
# Options that require values:
#  -o,--out-dir <dir>                            Uninstall files from cpack'd TGZ in <dir>
#                                                (default: none)
# @echo "$(rapids-select-cmake-install-args -h 2>&1 | tail -n-2 | head -n-1)"
# @echo "$(rapids-select-cmake-install-args -h 2>&1 | tail -n-4 | head -n-3)"

# shellcheck disable=SC1091
. rapids-generate-docstring;

_list_archive() {
    find "${outd}/" -regextype sed -iregex ".*/${patt}.tar.gz" -print0 \
  | xargs -0 ${v:+-t} -r -I% tar -tzf "%"                              \
  | sed -r "s/^${patt}/${prefix//\//\\/}/I"                            \
  ;
}

uninstall_${CPP_LIB}_cpp() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args "$@" ${CPP_CPACK_ARGS} <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'uninstall-all uninstall-${NAME} uninstall-${CPP_LIB}-cpp';

    ((${#component[@]})) || component=(all);

    prefix="$(realpath -ms "${prefix:-${CONDA_PREFIX:-${CMAKE_INSTALL_PREFIX:-/usr}}}")";

    time (
        local i;
        local -r kernel="$(uname -s)";

        for ((i=0; i < ${#component[@]}; i+=1)); do
            local comp="${component[$i]}";
            if test "all" = "${comp}";
                then comp="";
            fi

            if test -f "${CPP_SRC}/${BIN_DIR}/install_manifest${comp:+_$comp}.txt"; then
                xargs -rd "\n" --arg-file=<(<"${CPP_SRC}/${BIN_DIR}/install_manifest${comp:+_$comp}.txt" tr -d "\r") rm -f ${v:+-v} --;
            else

                local outd="";

                if test -z "${out_dir-}" || test "${#out_dir[@]}" -eq 0; then
                    continue;
                elif test "${i}" -lt "${#out_dir[@]}"; then
                    outd="$(realpath -ms "${out_dir[$i]}")";
                else
                    outd="$(realpath -ms "${out_dir[${#out_dir[@]}-1]}")";
                fi

                # shellcheck disable=SC2016
                if test -n "${outd:-}"; then
                    local patt="cudf-.*${comp:+-$comp}-${kernel}";
                    _list_archive | grep -Ev '^.*/$' | xargs -rd'\n' rm -f ${v:+-v} --;
                    _list_archive | grep -E '^.*/$'  | xargs -rd'\n' rmdir ${v:+-v} --ignore-fail-on-non-empty 2>/dev/null || true;
                fi
            fi
        done
        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} uninstall time:";
    ) 2>&1;
}

uninstall_${CPP_LIB}_cpp "$@" <&0;
