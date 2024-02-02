#!/usr/bin/env bash

# Usage:
#  cpack-${CPP_LIB}-cpp [OPTION]...
#
# CPack ${CPP_LIB}.
#
# Boolean options:
#  -h,--help                                    print this text
#  -v,--verbose                                 verbose output
#
# Options that require values:
#  -j,--parallel <num>                          Use <num> to compress in parallel
#                                               (default: $(nproc))
#  --component <comp>                           Component-based install. Only install component <comp>.
#                                               (default: all)
#  --config    <cfg>                            For multi-configuration generators, choose configuration <cfg>
#                                               (default: none)
#  --default-directory-permissions <permission> Default install permission. Use default permission <permission>.
#  -o,--out-dir <dir>                           copy cpack'd TGZ file into <dir>
#                                               (default: none)

cpack_${CPP_LIB}_cpp() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"cpack-all"*}" \
      || test -z "${rapids_build_utils_debug##*"cpack-${CPP_LIB}-cpp"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" --skip '
        -v,--verbose
        --strip
        --config
        --default-directory-permissions
    ' - <<< "${@@Q}")";

    if ! test -f "${CPP_SRC}/build/latest/CMakeCache.txt"; then
        exit 0;
    fi

    eval "$(rapids-get-num-archs-jobs-and-load -a1 "$@")";

    test ${#component[@]} -eq 0 && component=(all);

    time (
        local comp;
        local name;
        local slug;
        local outd;
        local vers;
        local kernel;

        kernel="$(uname -s)";

        if test -f "${CPP_SRC}"/build/latest/CPackConfig.cmake; then
            name="$(grep -e '^set(CPACK_PACKAGE_NAME ".*")$' "${CPP_SRC}"/build/latest/CPackConfig.cmake | head -n1)";
            vers="$(grep -e '^set(CPACK_PACKAGE_VERSION ".*")$' "${CPP_SRC}"/build/latest/CPackConfig.cmake | head -n1)";
            name="${name#*\"}"; name="${name%\"*}";
            vers="${vers#*\"}"; vers="${vers%\"*}";
        elif test -f "${CPP_SRC}"/build/latest/CPackSourceConfig.cmake; then
            name="$(grep -e '^set(CPACK_PACKAGE_NAME ".*")$' "${CPP_SRC}"/build/latest/CPackSourceConfig.cmake | head -n1)";
            vers="$(grep -e '^set(CPACK_PACKAGE_VERSION ".*")$' "${CPP_SRC}"/build/latest/CPackSourceConfig.cmake | head -n1)";
            name="${name#*\"}"; name="${name%\"*}";
            vers="${vers#*\"}"; vers="${vers%\"*}";
        else
            if grep -qe '^CMAKE_PROJECT_NAME:.*=.*$' "${CPP_SRC}"/build/latest/CMakeCache.txt; then
                name="$(grep -e '^CMAKE_PROJECT_NAME:.*=.*$' "${CPP_SRC}"/build/latest/CMakeCache.txt | head -n1)";
                name="${name##*=}";
            fi
            if grep -qe '^CMAKE_PROJECT_VERSION:.*=.*$' "${CPP_SRC}"/build/latest/CMakeCache.txt; then
                vers="$(grep -e '^CMAKE_PROJECT_VERSION:.*=.*$' "${CPP_SRC}"/build/latest/CMakeCache.txt | head -n1)";
                vers="${vers##*=}";
            elif test -f "${CPP_SRC}"/build/latest/${CPP_LIB}ConfigVersion.cmake; then
                vers="$(grep -e '^set(PACKAGE_VERSION ".*")$' "${CPP_SRC}"/build/latest/${CPP_LIB}ConfigVersion.cmake | head -n1)";
                vers="${vers#*\"}"; vers="${vers%\"*}";
            elif test -f "${CPP_SRC}"/build/latest/${CPP_LIB}-config-version.cmake; then
                vers="$(grep -e '^set(PACKAGE_VERSION ".*")$' "${CPP_SRC}"/build/latest/${CPP_LIB}-config-version.cmake | head -n1)";
                vers="${vers#*\"}"; vers="${vers%\"*}";
            fi
        fi

        if test -z "${name:-}" || test -z "${vers:-}"; then
            exit 1;
        fi

        for comp in "${component[@]}"; do

            if test "all" = "${comp}";
                then comp="";
            fi

            slug="${name}-${vers}${comp:+-$comp}-${kernel}";
            outd="${CPP_SRC}/build/latest/_CPack_Packages/${kernel}/TGZ";

            install-${CPP_LIB}-cpp -p "${outd}/${slug}" ${comp:+--component "${comp}"} "${OPTS[@]}";

            if test -d "${outd}/${slug}"; then
                tar -C "${outd}" -c ${v:+-v} -f "${outd}/${slug}.tar.gz" -I "pigz -p ${n_jobs}" "${slug}";
                cp -a "${outd}/${slug}.tar.gz" "${CPP_SRC}/build/latest/";
                if test -d "${out_dir}"/ \
                && test -f "${CPP_SRC}/build/latest/${slug}.tar.gz"; then
                    cp -a "${CPP_SRC}/build/latest/${slug}.tar.gz" "${out_dir}"/;
                fi
            fi
        done

        { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB} CPack time:";
    ) 2>&1;
}

cpack_${CPP_LIB}_cpp "$@";
