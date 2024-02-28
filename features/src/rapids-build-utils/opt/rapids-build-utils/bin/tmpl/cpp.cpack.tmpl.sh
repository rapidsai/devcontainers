#!/usr/bin/env bash

# Usage:
#  cpack-${CPP_LIB}-cpp [OPTION]...
#
# CPack ${CPP_LIB}.
#
# Boolean options:
#  -h,--help                                     Print this text.
# @_include_bool_options rapids-select-cmake-install-args -h | tail -n-3 | head -n-1;
#
# Options that require values:
#  -j,--parallel <num>                           Use <num> threads to compress in parallel
#                                                (default: $(nproc))
#  -o,--out-dir <dir>                            copy cpack'd TGZ file into <dir>
#                                                (default: none)
# @_include_value_options rapids-select-cmake-install-args -h | tail -n-5 | head -n-2;

# shellcheck disable=SC1091
. rapids-generate-docstring;

cpack_${CPP_LIB}_cpp() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '
        -j,--parallel
        -o,--out-dir
        --component
    ' "$@" ${CPP_CPACK_ARGS} <&0)";

    if ! test -f "${CPP_SRC}/${BIN_DIR}/CMakeCache.txt"; then
        exit 0;
    fi

    eval "$(                                              \
    PARALLEL_LEVEL=${PARALLEL_LEVEL:-$(nproc)}            \
        rapids-get-num-archs-jobs-and-load --archs 0 "$@" \
    )";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'cpack-all cpack-${NAME} cpack-${CPP_LIB}-cpp';

    ((${#component[@]})) || component=(all);

    time (
        local i;
        local name;
        local slug;
        local outd;
        local vers;
        local kernel;

        kernel="$(uname -s)";

        if test -f "${CPP_SRC}/${BIN_DIR}/CPackConfig.cmake"; then
            name="$(grep -e '^set(CPACK_PACKAGE_NAME ".*")$' "${CPP_SRC}/${BIN_DIR}/CPackConfig.cmake" | head -n1)";
            vers="$(grep -e '^set(CPACK_PACKAGE_VERSION ".*")$' "${CPP_SRC}/${BIN_DIR}/CPackConfig.cmake" | head -n1)";
            name="${name#*\"}"; name="${name%\"*}";
            vers="${vers#*\"}"; vers="${vers%\"*}";
        elif test -f "${CPP_SRC}/${BIN_DIR}/CPackSourceConfig.cmake"; then
            name="$(grep -e '^set(CPACK_PACKAGE_NAME ".*")$' "${CPP_SRC}/${BIN_DIR}/CPackSourceConfig.cmake" | head -n1)";
            vers="$(grep -e '^set(CPACK_PACKAGE_VERSION ".*")$' "${CPP_SRC}/${BIN_DIR}/CPackSourceConfig.cmake" | head -n1)";
            name="${name#*\"}"; name="${name%\"*}";
            vers="${vers#*\"}"; vers="${vers%\"*}";
        else
            if grep -qe '^CMAKE_PROJECT_NAME:.*=.*$' "${CPP_SRC}/${BIN_DIR}/CMakeCache.txt"; then
                name="$(grep -e '^CMAKE_PROJECT_NAME:.*=.*$' "${CPP_SRC}/${BIN_DIR}/CMakeCache.txt" | head -n1)";
                name="${name##*=}";
            fi
            if grep -qe '^CMAKE_PROJECT_VERSION:.*=.*$' "${CPP_SRC}/${BIN_DIR}/CMakeCache.txt"; then
                vers="$(grep -e '^CMAKE_PROJECT_VERSION:.*=.*$' "${CPP_SRC}/${BIN_DIR}/CMakeCache.txt" | head -n1)";
                vers="${vers##*=}";
            elif test -f "${CPP_SRC}/${BIN_DIR}/${CPP_LIB}ConfigVersion.cmake"; then
                vers="$(grep -e '^set(PACKAGE_VERSION ".*")$' "${CPP_SRC}/${BIN_DIR}/${CPP_LIB}ConfigVersion.cmake" | head -n1)";
                vers="${vers#*\"}"; vers="${vers%\"*}";
            elif test -f "${CPP_SRC}/${BIN_DIR}/${CPP_LIB}-config-version.cmake"; then
                vers="$(grep -e '^set(PACKAGE_VERSION ".*")$' "${CPP_SRC}/${BIN_DIR}/${CPP_LIB}-config-version.cmake" | head -n1)";
                vers="${vers#*\"}"; vers="${vers%\"*}";
            fi
        fi

        name="${name:-${CPP_LIB}}";

        for ((i=0; i < ${#component[@]}; i+=1)); do

            local comp="${component[$i]}";

            if test "all" = "${comp}";
                then comp="";
            fi

            slug="${name}${vers:+-$vers}${comp:+-$comp}-${kernel}";
            outd="${CPP_SRC}/${BIN_DIR}/_CPack_Packages/${kernel}/TGZ";

            install-${CPP_LIB}-cpp --prefix "${outd}/${slug}" ${comp:+--component "${comp}"} "${OPTS[@]}" >/dev/null 2>&1;

            if test -d "${outd}/${slug}"; then
                tar -C "${outd}" -c ${v:+-v} -f "${outd}/${slug}.tar.gz" -I "pigz -p ${n_jobs}" "${slug}";
                cp -a "${outd}/${slug}.tar.gz" "${CPP_SRC}/${BIN_DIR}/";

                if test -z "${out_dir-}" || test "${#out_dir[@]}" -eq 0; then
                    continue;
                elif test "${i}" -lt "${#out_dir[@]}"; then
                    outd="$(realpath -ms "${out_dir[$i]}")";
                else
                    outd="$(realpath -ms "${out_dir[${#out_dir[@]}-1]}")";
                fi

                if test -n "${outd:-}"; then
                    mkdir -p "${outd}/";
                    cp -a "${CPP_SRC}/${BIN_DIR}/${slug}.tar.gz" "${outd}/";
                fi
            fi
        done

        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} CPack time:";
    ) 2>&1;
}

cpack_${CPP_LIB}_cpp "$@" <&0;
