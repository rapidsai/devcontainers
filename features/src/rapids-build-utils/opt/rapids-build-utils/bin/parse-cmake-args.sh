#!/usr/bin/env bash

# Usage:
#  rapids-parse-cmake-args [OPTION]...
#
# Filter an arguments list to the subset that CMake accepts.
#
# Boolean options:
#  -h,--help                      Print usage information and exit.
#  -H,--help                      Print usage information and exit.
#  --debug-trycompile             Do not delete the try_compile build tree. Only useful on one try_compile at a time.
#  --debug-output                 Put cmake in a debug mode.
#  --debug-find                   Put cmake find in a debug mode.
#  --fresh                        Configure a fresh build tree, removing any existing cache file.
#  --find-package                 Legacy pkg-config like mode.  Do not use.
#  --log-context                  Prepend log messages with context, if given
#  --trace                        Put cmake in trace mode.
#  --trace-expand                 Put cmake in trace mode with variable expansion.
#  --warn-uninitialized           Warn about uninitialized values.
#  --no-warn-unused-cli           Don't warn about command line options.
#  --check-system-vars            Find problems with variable usage in system files.
#  --compile-no-warning-as-error  Ignore COMPILE_WARNING_AS_ERROR property and CMAKE_COMPILE_WARNING_AS_ERROR variable.
#
# Options that require values:
#  -S <path>                       Explicitly specify a source directory.
#  -B <path>                       Explicitly specify a build directory.
#  -C <path>                       Pre-load a script to populate the cache.
#  -D <var>[:<type>]=<value>       Create or update a cmake cache entry.
#  -U <globbing_expr>              Remove matching entries from CMake cache.
#  -G <generator-name>             Specify a build system generator.
#  -T <toolset-name>               Specify toolset name if supported by generator.
#  -A <platform-name>              Specify platform name if supported by generator.
#  --toolchain <file>              Specify toolchain file [CMAKE_TOOLCHAIN_FILE].
#  --install-prefix <directory>    Specify install directory [CMAKE_INSTALL_PREFIX].
#  -W (dev)                        Enable developer warnings.
#  -W (no-dev)                     Suppress developer warnings.
#  -W (deprecated)                 Enable deprecation warnings.
#  -W (no-deprecated)              Suppress deprecation warnings.
#  -W (error=dev)                  Make developer warnings errors.
#  -W (no-error=dev)               Make developer warnings not errors.
#  -W (error=deprecated)           Make deprecated macro and function warnings errors.
#  -W (no-error=deprecated)        Make deprecated macro and function warnings not errors.
#  --preset <preset>               Specify a configure preset.
#  --graphviz <file>               Generate graphviz of dependencies, see CMakeGraphVizOptions.cmake for more.
#  --loglevel,--log-level (ERROR|WARNING|NOTICE|STATUS|VERBOSE|DEBUG|TRACE)
#                                  Set the verbosity of messages from CMake files. --loglevel is also accepted for backward compatibility reasons.
#  --debug-find-pkg <pkg-name>     Limit cmake debug-find to the comma-separated list of packages
#  --debug-find-var <var-name>     Limit cmake debug-find to the comma-separated list of result variables
#  --trace-format (human|json-v1)  Set the output format of the trace.
#  --trace-source <file>           Trace only this CMake file/module.  Multiple options allowed.
#  --trace-redirect <file>         Redirect trace output to a file instead of stderr.
#  --profiling-format <fmt>        Output data for profiling CMake scripts. Supported formats: google-trace
#  --profiling-output <file>       Select an output path for the profiling data enabled through --profiling-format.

# shellcheck disable=SC1091
. devcontainer-utils-parse-args-from-docstring;

parse_cmake_args() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
          || test -z "${rapids_build_utils_debug##*"parse-args"*}" \
          || test -z "${rapids_build_utils_debug##*"parse-cmake-args"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args rapids-parse-cmake-args "$@" <&0)";

    local -r usage="$(print_usage "$(realpath -m "${BASH_SOURCE[0]}")")";
    local -ar long_bools="($(parse_bool_names_from_usage   <<< "${usage}" | parse_long_names))";
    local -ar long_value="($(parse_value_names_from_usage  <<< "${usage}" | parse_long_names))";
    local -ar short_bools="($(parse_bool_names_from_usage  <<< "${usage}" | parse_short_names))";
    local -ar short_value="($(parse_value_names_from_usage <<< "${usage}" | parse_short_names | grep -vP '(S|B|G|C|U|T|A)'))";

    local k;
    local cmake_args=();

    for k in "${short_bools[@]}"; do
        local -n v=${k//-/_};
        if test -n "${v[*]:-}"; then
            cmake_args+=("-${k}");
        fi
    done
    unset "${short_bools[@]//-/_}";

    # short value options that might need spaces
    for k in S B G C U T A; do
        local -n v=${k//-/_};
        cmake_args+=("${v[@]/#/-${k} }");
    done
    unset S B G C U T A;

    # All other value opts should be fine w/o spaces
    for k in "${short_value[@]}"; do
        local -n v=${k//-/_};
        cmake_args+=("${v[@]/#/-${k}}");
    done
    unset "${short_value[@]//-/_}";

    for k in "${long_bools[@]}"; do
        local -n v=${k//-/_};
        if test -n "${v[*]:-}"; then
            cmake_args+=("--${k}");
        fi
    done
    unset "${long_bools[@]//-/_}";

    for k in "${long_value[@]}"; do
        local -n v=${k//-/_};
        cmake_args+=("${v[@]/#/--${k}=}");
    done
    unset "${long_value[@]//-/_}";

    echo "${cmake_args[@]}";
}

parse_cmake_args "$@" <&0;
