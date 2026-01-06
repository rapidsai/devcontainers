#!/usr/bin/env bash

# Usage:
#  . rapids-generate-docstring
#
# Parses the docstring of the source script and evaluates
# its @_include_<X> statements to the functions in this file.
#
# The evaluated docstring is cached in `/tmp/rapids-build-utils/.docstrings-cache/`.

if ((${#BASH_SOURCE[@]})) && [ "${BASH_SOURCE[0]}" != "${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}" ]; then

    # shellcheck disable=SC1091
    source devcontainer-utils-parse-args;

    __cmd="${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}";

    _include_usage() {
        local -;
        set -euo pipefail;
        _print_usage "$@" | sed -rn "0,/^(\
[ ]{1,4}-\
|Options:\
|Boolean options:\
|Options that require values:\
|Positional arguments\
|CMake Options:\
|CMake Build Options:\
|CMake Install Options:\
|General Options\
|Install Options\
|Wheel Options\
|Package Index Options\
)/I{x;p}";
    }

    _include_options() {
        local expr="/^([ ]{1,4}-\
|Options:\
|Boolean options:\
|Options that require values:\
|CMake Options:\
|CMake Build Options:\
|CMake Install Options:\
|General Options\
|Install Options\
|Wheel Options\
|Package Index Options\
)/,/^$/p"
        if test $# -gt 0; then
            devcontainer_utils_debug="" rapids_build_utils_debug="" \
            "$@" 2>&1 | sed -rn "${expr}";
        else
            devcontainer_utils_debug="" rapids_build_utils_debug="" \
            ${__cmd} -h 2>&1 | sed -rn "${expr}";
        fi
    }

    _include_bool_options() {
        if test $# -gt 0; then
            devcontainer_utils_debug="" rapids_build_utils_debug="" \
            "$@" 2>&1 | sed -n '/^Boolean options:$/,/^$/p';
        else
            devcontainer_utils_debug="" rapids_build_utils_debug="" \
            ${__cmd} -h 2>&1 | sed -n '/^Boolean options:$/,/^$/p';
        fi
    }

    _include_value_options() {
        if test $# -gt 0; then
            devcontainer_utils_debug="" rapids_build_utils_debug="" \
            "$@" 2>&1 | sed -n '/^Options that require values:$/,/^$/p';
        else
            devcontainer_utils_debug="" rapids_build_utils_debug="" \
            ${__cmd} -h 2>&1 | sed -n '/^Options that require values:$/,/^$/p';
        fi
    }

    _include_cmake_options() {
        _include_options rapids-select-cmake-args -h;
    }

    _include_cmake_build_options() {
        _include_options rapids-select-cmake-build-args -h;
    }

    _include_cmake_install_options() {
        _include_options rapids-select-cmake-install-args -h;
    }

    _include_pip_general_options() {
        local doc="/tmp/rapids-build-utils/.docstrings-cache/pip.txt";
        if ! test -f "${doc}"; then
            pip --help > "${doc}" 2>&1;
        fi
        sed -n '/^General Options/,/^$/p' "${doc}";
    }

    _include_pip_package_index_options() {
        local doc="/tmp/rapids-build-utils/.docstrings-cache/pip-install.txt";
        if ! test -f "${doc}"; then
            pip install --help > "${doc}" 2>&1;
        fi
        sed -n '/^Package Index Options/,/^$/p' "${doc}";
    }

    _include_pip_install_options() {
        local doc="/tmp/rapids-build-utils/.docstrings-cache/pip-install.txt";
        if ! test -f "${doc}"; then
            pip install --help > "${doc}" 2>&1;
        fi
        sed -n '/^Install Options/,/^$/p' "${doc}";
    }

    _include_pip_wheel_options() {
        local doc="/tmp/rapids-build-utils/.docstrings-cache/pip-wheel.txt";
        if ! test -f "${doc}"; then
            pip wheel --help > "${doc}" 2>&1;
        fi
        sed -n '/^Wheel Options/,/^$/p' "${doc}";
    }

    _generate_docstring() {
        local -;
        set -euo pipefail;

        # shellcheck disable=SC1091
        . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'generate-docstring';

        local cmd="${1:?missing required positional argument CMD}"; shift;
        local out="${1:?missing required positional argument OUT}"; shift;

        # rm -f "${out}";

        if test -s "${out}"; then return; fi

        mkdir -p "$(dirname "${out}")";

        local re="^@(\
echo|\
_include_usage|\
_include_options|\
_include_bool_options|\
_include_value_options|\
_include_cmake_options|\
_include_cmake_build_options|\
_include_cmake_install_options|\
_include_pip_general_options|\
_include_pip_package_index_options|\
_include_pip_install_options|\
_include_pip_wheel_options\
).*?$";
        while IFS= read -er line; do
            if [[ "${line}" =~ ${re} ]]; then
                eval "${line:1}";
            else
                echo "${line}";
            fi
        done < <(_print_usage "${cmd}") | sed 's/^/# /' > "${out}";
    }

    _filter_args() {
        local -;
        set -euo pipefail;
        eval "$(_parse_args "$@" <&0)";
        echo "${ARGS[*]@Q}";
    }

    _parse_args() {
        # shellcheck disable=SC1091
        . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'parse-args';
        _parse_args_for_file "${__doc}" "$@" <&0;
    }

    __doc="/tmp/rapids-build-utils/.docstrings-cache/${__cmd//\//-}.txt";

    _generate_docstring "${__cmd}" "${__doc}";
fi
