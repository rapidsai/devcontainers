#!/usr/bin/env bash

# Usage:
#  rapids-make-pip-dependencies [OPTION]...
#
# Generate a combined pip requirements file for all repos.
#
# Boolean options:
#  -h,--help               Print this text.
#  --no-dedupe             Don't sort and dedupe the combined requirements.txt.
#
# Options that require values:
#  -e,--exclude <file>     Path(s) to requirement files of packages to exclude.
#                          Can also be a file descriptor like '<(echo libucx)'.
#  -i,--include <file>     Path(s) to requirement files of packages to include.
#                          Can also be a file descriptor like '<(echo libucx)'.
#  -k,--key <key>          Only include the key(s)
#  --matrix-entry <entry>  Matrix entries, in the form 'key=value' to be added to the '--matrix' arg
#                          of rapids-dependency-file-generator.
#                          (can be passed multiple times)
# @_include_value_options rapids-list-repos -h | tail -n+2 | head -n-3;
#  --repo <repo>           Only include dependencies for repo(s).
#                          (default: all repositories)
#  -r,--requirement <file> Path(s) to additional requirement files to include.

# shellcheck disable=SC1091
. rapids-generate-docstring;

_generate_requirements_txt() {
    if rapids-dependency-file-generator "$@" 2>/dev/null \
     | grep -v '^#' 2>/dev/null \
     | tee "$file" 1>/dev/null; then
        echo "$file"
    fi
}

_generate_requirements_txts() {
    local i;
    local j;

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_name="${repo}_name";
        local repo_path="${repo}_path";
        local name="${!repo_name:-}";
        local path="${!repo_path:-}";

        if test -n "${name:+x}" \
        && test -n "${path:+x}" \
        && test -f ~/"${path}/dependencies.yaml"; then

            echo "Generating ${name}'s repo requirements.txt" 1>&2;

            local dependency_keys=("${key[@]}");

            local repo_dependency_keys_length="${repo}_dependency_keys_length";
            for ((j=0; j < ${!repo_dependency_keys_length:-0}; j+=1)); do
                local dependency_key="${repo}_dependency_keys_${j}";
                dependency_key="${!dependency_key:-}";
                if test -n "${dependency_key:+x}"; then
                    dependency_keys+=("${dependency_key}");
                fi
            done

            if test ${#dependency_keys[@]} -eq 0; then
                dependency_keys=(py_build py_run py_test all);
            fi

            local keys=("${dependency_keys[@]}");
            local keyi;

            for ((keyi=0; keyi < ${#keys[@]}; keyi+=1)); do
                local file="${tmpdir}/${name}.${keys[$keyi]}.requirements.txt";
                pip_reqs_txts+=("${file}");
                _generate_requirements_txt                 \
                    --file-key "${keys[$keyi]}"            \
                    --output requirements                  \
                    --config ~/"${path}/dependencies.yaml" \
                    --matrix "${matrix_selectors}"         &
            done

            local cpp_length="${repo}_cpp_length";

            for ((j=0; j < ${!cpp_length:-0}; j+=1)); do
                local cpp_name="${repo}_cpp_${j}_name";
                local cpp_name="lib${!cpp_name}";

                echo "Generating ${cpp_name}'s requirements.txt" 1>&2;

                local keys=("${dependency_keys[@]/%/_${cpp_name//"-"/"_"}}");
                local keyi;

                for ((keyi=0; keyi < ${#keys[@]}; keyi+=1)); do
                    local file="${tmpdir}/${name}.${cpp_name}.${keys[$keyi]}.requirements.txt";
                    pip_reqs_txts+=("${file}");
                    _generate_requirements_txt                 \
                        --file-key "${keys[$keyi]}"            \
                        --output requirements                  \
                        --config ~/"${path}/dependencies.yaml" \
                        --matrix "${matrix_selectors}"         &
                done
            done

            local py_length="${repo}_python_length";

            for ((j=0; j < ${!py_length:-0}; j+=1)); do
                local py_name="${repo}_python_${j}_name";
                local py_name="${!py_name}";

                echo "Generating ${py_name}'s requirements.txt" 1>&2;

                local keys=("${dependency_keys[@]/%/_${py_name//"-"/"_"}}");
                local keyi;

                for ((keyi=0; keyi < ${#keys[@]}; keyi+=1)); do
                    local file="${tmpdir}/${name}.${py_name}.${keys[$keyi]}.requirements.txt";
                    pip_reqs_txts+=("${file}");
                    _generate_requirements_txt                 \
                        --file-key "${keys[$keyi]}"            \
                        --output requirements                  \
                        --config ~/"${path}/dependencies.yaml" \
                        --matrix "${matrix_selectors}"         &
                done
            done
        fi
    done
}

_make_pip_dependencies() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --skip '-m,--manifest -o,--omit --repo' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'make-pip-env make-pip-dependencies';

    test ${#exclude[@]} -eq 0 && exclude=();
    test ${#include[@]} -eq 0 && include=();
    test ${#matrix_entry[@]} -eq 0 && matrix_entry=();
    test ${#requirement[@]} -eq 0 && requirement=();

    local -a _exclude=();
    local exc; for exc in "${exclude[@]}"; do
        # append '-f' so each file's contents will be treated as a list of patterns for 'grep'
        _exclude+=(-f "${exc}");
    done

    local -a _include=();
    local inc; for inc in "${include[@]}"; do
        # append '-f' so each file's contents will be treated as a list of patterns for 'grep'
        _include+=(-f "${inc}");
    done

    local cuda_version="${CUDA_VERSION_MAJOR_MINOR:-}";
    local -r cuda_version_major="$(cut -d'.' -f1 <<< "${cuda_version}")";

    local python_version="${PYTHON_VERSION:-$("${ORIG_PYTHON:-python3}" --version 2>&1 | cut -d' ' -f2)}";
    python_version="$(cut -d'.' -f3 --complement <<< "${python_version}")";

    # Why default to cuda_suffixed=true?
    #
    # Projects that depend on different pip libraries across different CUDA versions
    # (e.g. 'cudf' only depending on 'pynvjitlink' from CUDA 12.0 onwards), split up their
    # dependency lists with 'cuda_suffixed={true,false}'.
    #
    # Here we want the suffixed versions (like 'pynvjitlink-cu12').
    #
    # It's ok for other RAPIDS libraries to end up in this list (like 'rmm-cu12')... in builds
    # where those are also being built in the devcontainer, they'll be filtered out via
    # inclusion in the 'pip_noinstall' list below.
    local -a _matrix_selectors=(
        arch="$(uname -m)"
        cuda="${cuda_version}"
        cuda_suffixed=true
        py="${python_version}"
        use_cuda_wheels=false
    );

    # add extra arguments (if there are conflicts, e.g. 'py=3.10;py=3.11', it's fine... the last one will win)
    test ${#matrix_entry[@]} -gt 0 && _matrix_selectors+=("${matrix_entry[@]}");
    local -r matrix_selectors=$(IFS=";"; echo "${_matrix_selectors[*]}")

    local -r tmpdir="$(mktemp -d)";
    # shellcheck disable=SC2064
    trap "rm -rf '${tmpdir}'" EXIT;

    eval "$(rapids-list-repos "${OPTS[@]}")";

    readarray -t pip_reqs_txts < <(_generate_requirements_txts);

    if test ${#requirement[@]} -gt 0 || test ${#pip_reqs_txts[@]} -gt 0; then

        readarray -t rapids_python_pkg_names < <(rapids-python-pkg-names);

        # add all python packages to the noinstall list.
        local -a pip_noinstall=();
        pip_noinstall+=("${rapids_python_pkg_names[@]}");
        pip_noinstall+=("${rapids_python_pkg_names[@]//"-"/"_"}");
        pip_noinstall+=("${rapids_python_pkg_names[@]//"_"/"-"}");
        pip_noinstall+=("${pip_noinstall[@]/%/"-cu.*"}");

        # Generate a combined requirements.txt file
        # shellcheck disable=SC2002
        cat "${requirement[@]}" "${pip_reqs_txts[@]}"                                                           \
      | (grep -v '^#' || [ "$?" == "1" ])                                                                       \
      | (grep -v -E '^$' || [ "$?" == "1" ])                                                                    \
      | ( if test -n "${no_dedupe:+x}"; then cat -; else tr -s "[:blank:]" | LC_ALL=C sort -u; fi )             \
      | (grep -v -P "^($(tr -d '[:blank:]' <<< "${pip_noinstall[@]/%/|}"))(=.*|>.*|<.*)?$" || [ "$?" == "1" ])  \
      | ( if test ${#_exclude[@]} -gt 0; then grep -E -v "${_exclude[@]}" || [ "$?" == "1" ]; else cat -; fi )  \
      | ( if test ${#_include[@]} -gt 0; then grep -E    "${_include[@]}" || [ "$?" == "1" ]; else cat -; fi )  \
      | sed -E "s/-cu([0-9]+)/-cu${cuda_version_major}/g"                                                       \
      | sed -E "s/^cupy-cuda[0-9]+x/cupy-cuda${cuda_version_major}x/g"                                          \
      | sed -E "s/^cuda-python.*/cuda-python>=${cuda_version}.0,<$((cuda_version_major+1)).0a0/g"               \
        ;
    fi
}

_make_pip_dependencies "$@" <&0;
