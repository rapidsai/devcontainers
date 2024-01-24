#!/usr/bin/env bash

# Usage:
#  install-${CPP_LIB}-cpp [OPTION]...
#
# Install ${CPP_LIB}.
#
# Boolean options:
#  -h,--help,--usage            print this text
#  -v,--verbose                 Enable verbose output.
#  --strip                      Strip before installing.
#
# Options that require values:
#  -p,--prefix <dir>                            Install C++ library into <dir>
#                                               (default: none)
#  --config    <cfg>                            For multi-configuration generators, choose configuration <cfg>
#                                               (default: none)
#  --component <comp>                           Component-based install. Only install component <comp>.
#                                               (default: all)
#  --default-directory-permissions <permission> Default install permission. Use default permission <permission>.

. devcontainer-utils-parse-args-from-docstring;

install_${CPP_LIB}_cpp() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    local strip="${strip:-}";
    local verbose="${v:-${verbose:-}}";
    local config="${config:+--config "${config}"}";
    local components=(${component[@]:-all}); unset component;
    local prefix="${p:-${prefix:-${CMAKE_INSTALL_PREFIX:-/usr/local}}}";
    local default_directory_permissions="${default_directory_permissions:+--default-directory-permissions "${default_directory_permissions}"}";

    for ((i=0; i < ${#components[@]}; i+=1)); do
        local component="${components[$i]}";
        if test "all" = "${component}"; then
            component="";
        fi
        time (
            cmake \
                --install "${CPP_SRC}"/build/latest/     \
                ${strip:+--strip}                        \
                ${verbose:+--verbose}                    \
                ${prefix:+--prefix "${prefix}"}          \
                ${default_directory_permissions}         \
                ${component:+--component "${component}"} \
                ;
            { set +x; } 2>/dev/null; echo -n "lib${CPP_LIB}${component:+ $component} install time:";
        ) 2>&1;
    done
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"install-${CPP_LIB}-cpp"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

install_${CPP_LIB}_cpp "$@";
