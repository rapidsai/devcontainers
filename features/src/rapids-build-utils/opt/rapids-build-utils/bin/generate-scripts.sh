#!/usr/bin/env bash

# shellcheck disable=SC2016

ALT_SCRIPT_DIR="${ALT_SCRIPT_DIR:-/usr/bin}";
TEMPLATES="${TEMPLATES:-/opt/rapids-build-utils/bin/tmpl}";
TMP_SCRIPT_DIR="${TMP_SCRIPT_DIR:-/tmp/rapids-build-utils}";
COMPLETION_TMPL="${COMPLETION_TMPL:-"$(which devcontainer-utils-bash-completion.tmpl)"}";
COMPLETION_FILE="${COMPLETION_FILE:-${HOME}/.bash_completion.d/rapids-build-utils-completions}";

generate_completions() {
    local -;
    set -euo pipefail;

    if command -v devcontainer-utils-debug-output >/dev/null 2>&1; then
        # shellcheck disable=SC1091
        . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'generate-scripts';

        readarray -t commands < <(find "${TMP_SCRIPT_DIR}"/ -maxdepth 1 -type f -exec basename {} \;);

        devcontainer-utils-generate-bash-completion          \
            --out-file "$(realpath -m "${COMPLETION_FILE}")" \
            --template "$(realpath -m "${COMPLETION_TMPL}")" \
            ${commands[@]/#/--command }                      \
        ;
    fi
}

clean_scripts_and_aliases() {
    local -;
    set -euo pipefail;

    if command -v devcontainer-utils-debug-output >/dev/null 2>&1; then
        # shellcheck disable=SC1091
        . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'generate-scripts';
    fi

    readarray -t commands < <(find "${TMP_SCRIPT_DIR}"/ -maxdepth 1 -type f -exec basename {} \;);
    sudo rm -f -- \
        "${commands[@]/#/${ALT_SCRIPT_DIR}\/}" \
        "${commands[@]/#/${TMP_SCRIPT_DIR}\/}" ;
}

generate_script() {
    local bin="${1:-}";
    if test -n "${bin:+x}"; then
        (
            cat - \
          | envsubst '$HOME $NAME $SRC_PATH $PY_ENV $PY_SRC $PY_LIB $BIN_DIR $CPP_ENV $CPP_LIB $CPP_SRC $CPP_CMAKE_ARGS $CPP_CPACK_ARGS $CPP_DEPS $CPP_MAX_TOTAL_SYSTEM_MEMORY $CPP_MAX_DEVICE_OBJ_MEMORY_USAGE $CPP_MAX_DEVICE_OBJ_TO_COMPILE_IN_PARALLEL $GIT_TAG $GIT_SSH_URL $GIT_HTTPS_URL $GIT_REPO $GIT_HOST $GIT_UPSTREAM $PIP_WHEEL_ARGS $PIP_INSTALL_ARGS' \
          | tee "${TMP_SCRIPT_DIR}/${bin}" >/dev/null;

            chmod +x "${TMP_SCRIPT_DIR}/${bin}";

            sudo ln -sf "${TMP_SCRIPT_DIR}/${bin}" "${ALT_SCRIPT_DIR}/${bin}";

            if [[ "${bin}" != "${bin,,}" ]]; then
                sudo ln -sf "${TMP_SCRIPT_DIR}/${bin,,}" "${ALT_SCRIPT_DIR}/${bin,,}";
            fi
        ) & true;

        echo "$!"
    fi
}

generate_all_script_impl() {
    local bin="${SCRIPT}-all";
    if test -n "${bin:+x}" && ! test -f "${TMP_SCRIPT_DIR}/${bin}"; then
        (
            cat - \
          | envsubst '$NAME $NAMES $SCRIPT' \
          | tee "${TMP_SCRIPT_DIR}/${bin}" >/dev/null;

            chmod +x "${TMP_SCRIPT_DIR}/${bin}";

            sudo ln -sf "${TMP_SCRIPT_DIR}/${bin}" "${ALT_SCRIPT_DIR}/${bin}";
        ) & true;

        echo "$!"
    fi
}

generate_all_script() {
    if test -f "${TEMPLATES}/all.${SCRIPT}.tmpl.sh"; then (
        # shellcheck disable=SC2002
        cat "${TEMPLATES}/all.${SCRIPT}.tmpl.sh" \
      | generate_all_script_impl       ;
    ) || true;
    elif test -f "${TEMPLATES}/all.tmpl.sh"; then (
        # shellcheck disable=SC2002
        cat "${TEMPLATES}/all.tmpl.sh" \
      | generate_all_script_impl       ;
    ) || true;
    fi
}

generate_clone_script() {
    if test -f "${TEMPLATES}/repo.clone.tmpl.sh"; then (
        # shellcheck disable=SC2002
        cat "${TEMPLATES}/repo.clone.tmpl.sh" \
      | generate_script "clone-${NAME}"  ;
    ) || true;
    fi
}

generate_repo_scripts() {
    local script_name;
    for script_name in "configure" "build" "cpack" "clean" "install" "uninstall"; do
        if test -f "${TEMPLATES}/repo.${script_name}.tmpl.sh"; then (
            # shellcheck disable=SC2002
            cat "${TEMPLATES}/repo.${script_name}.tmpl.sh" \
          | generate_script "${script_name}-${NAME}"  ;
        ) || true;
        fi
    done
}

generate_cpp_scripts() {
    local script_name;
    for script_name in "clean" "configure" "build" "cpack" "install" "uninstall"; do
        if test -f "${TEMPLATES}/cpp.${script_name}.tmpl.sh"; then (
            # shellcheck disable=SC2002
            cat "${TEMPLATES}/cpp.${script_name}.tmpl.sh"  \
          | CPP_SRC="${SRC_PATH:-}${CPP_SRC:+/$CPP_SRC}"   \
            generate_script "${script_name}-${CPP_LIB-}-cpp";
        ) || true;
        fi
    done
}

generate_python_scripts() {
    local script_name;
    for script_name in "build" "clean" "install" "uninstall"; do
        if test -f "${TEMPLATES}/python.${script_name}.tmpl.sh"; then (
            # shellcheck disable=SC2002
            cat "${TEMPLATES}/python.${script_name}.tmpl.sh" \
          | generate_script "${script_name}-${PY_LIB}-python";
        ) || true;
        fi
    done
    for script_name in "editable" "wheel"; do
        if test -f "${TEMPLATES}/python.build.${script_name}.tmpl.sh"; then (
            # shellcheck disable=SC2002
            cat "${TEMPLATES}/python.build.${script_name}.tmpl.sh" \
          | generate_script "build-${PY_LIB}-python-${script_name}";
        ) || true;
        fi
    done
}

generate_scripts() {
    local -;
    set -euo pipefail;

    # Generate and install the "clone-<repo>" scripts

    # Ensure we're in this script's directory
    cd "$( cd "$( dirname "$(realpath -m "${BASH_SOURCE[0]}")" )" && pwd )";

    eval "$(rapids-list-repos "$@")";

    if command -v devcontainer-utils-debug-output >/dev/null 2>&1; then
        # shellcheck disable=SC1091
        . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'generate-scripts';
    fi

    local i;
    local j;
    local k;

    local repo;
    local repo_name;
    local repo_path;
    local cpp_length;
    local py_length;
    local git_repo;
    local git_host;
    local git_tag;
    local git_upstream;
    local git_ssh_url;
    local git_https_url;

    local cpp_name;
    local cpp_path;
    local cpp_sub_dir;
    local cpp_cmake_args;
    local cpp_cpack_args;
    local cpp_depends_length;
    local cpp_max_total_system_memory;
    local cpp_max_device_obj_memory_usage;
    local cpp_max_device_obj_to_compile_in_parallel;

    local py_env;
    local py_path;
    local py_name;
    local py_cmake_args;
    local pip_wheel_args;
    local pip_install_args;
    local py_sub_dir;
    local py_depends_length;

    local dep;
    local dep_name;
    local dep_path;

    local -A cpp_name_to_path;
    local -A cpp_name_to_deps;

    local -a py_libs=()
    local -a py_dirs=()
    local -a cpp_libs=();
    local -a cpp_dirs=();
    local -a cpp_deps=();

    local -a repo_names=();
    local -a cloned_repos=();
    local -a immediate_cpp_deps=();
    local -a inherited_cpp_deps=();

    local -r bin_dir="$(rapids-get-cmake-build-dir --skip-build-type)";

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        repo="repos_${i}";
        repo_name="${repo}_name";
        repo_path="${repo}_path";
        cpp_length="${repo}_cpp_length";
        py_length="${repo}_python_length";
        git_repo="${repo}_git_repo";
        git_host="${repo}_git_host";
        git_tag="${repo}_git_tag";
        git_upstream="${repo}_git_upstream";
        git_ssh_url="${repo}_git_ssh_url";
        git_https_url="${repo}_git_https_url";

        repo_name="${!repo_name,,}";
        repo_names+=("${repo_name}");

        if [[ -d ~/"${!repo_path:-}/.git" ]]; then
            cloned_repos+=("${repo_name}");
        fi

        py_libs=()
        py_dirs=()
        cpp_libs=();
        cpp_dirs=();

        for ((j=0; j < ${!cpp_length:-0}; j+=1)); do

            cpp_env="${repo}_cpp_${j}_env";
            cpp_name="${repo}_cpp_${j}_name";
            cpp_sub_dir="${repo}_cpp_${j}_sub_dir";
            cpp_cmake_args="${repo}_cpp_${j}_args_cmake";
            cpp_cpack_args="${repo}_cpp_${j}_args_cpack";
            cpp_depends_length="${repo}_cpp_${j}_depends_length";
            cpp_max_total_system_memory="${repo}_cpp_${j}_parallelism_max_total_system_memory";
            cpp_max_device_obj_memory_usage="${repo}_cpp_${j}_parallelism_max_device_obj_memory_usage";
            cpp_max_device_obj_to_compile_in_parallel="${repo}_cpp_${j}_parallelism_max_device_obj_to_compile_in_parallel";
            cpp_path=~/"${!repo_path:-}${!cpp_sub_dir:+/${!cpp_sub_dir}}";

            cpp_dirs+=("${cpp_path}");
            cpp_libs+=("${!cpp_name:-}");
            cpp_name="${!cpp_name:-}";

            cpp_name_to_path["${cpp_name}"]="${cpp_path}";

            immediate_cpp_deps=();
            inherited_cpp_deps=();

            for ((k=0; k < ${!cpp_depends_length:-0}; k+=1)); do
                dep="${repo}_cpp_${j}_depends_${k}";
                dep_name="${!dep}";
                if test -v cpp_name_to_path["${dep_name}"]; then
                    dep_path="${cpp_name_to_path["${dep_name}"]}";
                    immediate_cpp_deps+=("-D${dep_name}_ROOT=${dep_path}/${bin_dir}");
                    if test -v cpp_name_to_deps["${dep_name}"]; then
                        eval "inherited_cpp_deps+=(${cpp_name_to_deps["${dep_name}"]});"
                    fi
                fi
            done

            # shellcheck disable=SC2206
            cpp_deps=(${inherited_cpp_deps[@]@Q} ${immediate_cpp_deps[@]@Q});

            cpp_name_to_deps["${cpp_name}"]="${cpp_deps[*]}";

            if [[ -d ~/"${!repo_path:-}/.git" ]]; then
                NAME="${repo_name:-}"                                                                       \
                SRC_PATH=~/"${!repo_path:-}"                                                                \
                BIN_DIR="${bin_dir}"                                                                        \
                CPP_ENV="${!cpp_env:-}"                                                                     \
                CPP_LIB="${cpp_name:-}"                                                                     \
                CPP_SRC="${!cpp_sub_dir:-}"                                                                 \
                CPP_DEPS="${cpp_deps[*]}"                                                                   \
                CPP_CMAKE_ARGS="${!cpp_cmake_args:-}"                                                       \
                CPP_CPACK_ARGS="${!cpp_cpack_args:-}"                                                       \
                CPP_MAX_TOTAL_SYSTEM_MEMORY="${!cpp_max_total_system_memory:-}"                             \
                CPP_MAX_DEVICE_OBJ_MEMORY_USAGE="${!cpp_max_device_obj_memory_usage:-}"                     \
                CPP_MAX_DEVICE_OBJ_TO_COMPILE_IN_PARALLEL="${!cpp_max_device_obj_to_compile_in_parallel:-}" \
                generate_cpp_scripts                                                                        ;
            fi
        done

        for ((j=0; j < ${!py_length:-0}; j+=1)); do
            py_env="${repo}_python_${j}_env";
            py_name="${repo}_python_${j}_name";
            py_cmake_args="${repo}_python_${j}_args_cmake";
            pip_wheel_args="${repo}_python_${j}_args_wheel";
            pip_install_args="${repo}_python_${j}_args_install";
            py_sub_dir="${repo}_python_${j}_sub_dir";
            py_depends_length="${repo}_python_${j}_depends_length";
            py_path=~/"${!repo_path:-}${!py_sub_dir:+/${!py_sub_dir}}";

            immediate_cpp_deps=();
            inherited_cpp_deps=();

            for ((k=0; k < ${!py_depends_length:-0}; k+=1)); do
                dep="${repo}_python_${j}_depends_${k}";
                dep_name="${!dep}";
                if test -v cpp_name_to_path["${dep_name}"]; then
                    dep_path="${cpp_name_to_path["${dep_name}"]}";
                    immediate_cpp_deps+=("-D${dep_name}_ROOT=${dep_path}/${bin_dir}");
                    if test -v cpp_name_to_deps["${dep_name}"]; then
                        # shellcheck disable=SC2206
                        eval "inherited_cpp_deps+=(${cpp_name_to_deps["${dep_name}"]});"
                    fi
                fi
            done

            # shellcheck disable=SC2206
            cpp_deps=(${inherited_cpp_deps[@]@Q} ${immediate_cpp_deps[@]@Q});

            py_dirs+=("${py_path}");
            py_libs+=("${!py_name}");

            if [[ -d ~/"${!repo_path:-}/.git" ]]; then
                NAME="${repo_name:-}"                     \
                BIN_DIR="${bin_dir}"                      \
                SRC_PATH=~/"${!repo_path:-}"              \
                PY_SRC="${py_path}"                       \
                PY_LIB="${!py_name}"                      \
                PY_ENV="${!py_env:-}"                     \
                CPP_DEPS="${cpp_deps[*]}"                 \
                CPP_CMAKE_ARGS="${!py_cmake_args:-}"      \
                PIP_WHEEL_ARGS="${!pip_wheel_args:-}"     \
                PIP_INSTALL_ARGS="${!pip_install_args:-}" \
                generate_python_scripts                   ;
            fi
        done;

        if [[ -d ~/"${!repo_path:-}/.git" ]]; then
            NAME="${repo_name:-}"      \
            PY_LIB="${py_libs[*]@Q}"   \
            CPP_LIB="${cpp_libs[*]@Q}" \
            generate_repo_scripts      ;
        fi

        # Generate a clone script for each repo
        NAME="${repo_name:-}"               \
        SRC_PATH=~/"${!repo_path:-}"        \
        PY_LIB="${py_libs[*]@Q}"            \
        PY_SRC="${py_dirs[*]@Q}"            \
        CPP_LIB="${cpp_libs[*]@Q}"          \
        CPP_SRC="${cpp_dirs[*]@Q}"          \
        GIT_TAG="${!git_tag:-}"             \
        GIT_REPO="${!git_repo:-}"           \
        GIT_HOST="${!git_host:-}"           \
        GIT_UPSTREAM="${!git_upstream:-}"   \
        GIT_SSH_URL="${!git_ssh_url:-}"     \
        GIT_HTTPS_URL="${!git_https_url:-}" \
        generate_clone_script               ;
    done

    unset cpp_name_to_path;

    if ((${#repo_names[@]} > 0)); then
        for script in "clone" "clean" "configure" "build" "cpack" "install" "uninstall"; do
            # Generate a script to run a script for all repos
            NAME="${cloned_repos[0]:-${repo_names[0]:-}}" \
            NAMES="${repo_names[*]@Q}"  \
            SCRIPT="${script}"          \
            generate_all_script         ;
        done;
    fi
}

_generate() {
    local -;
    set -euo pipefail;

    echo "Generating RAPIDS build scripts in ${ALT_SCRIPT_DIR}" >&2;

    mkdir -p "${TMP_SCRIPT_DIR}";

    # Clean the cached parsed docstrings
    rm -rf /tmp/rapids-build-utils/.docstrings-cache/;
    # Bash completions
    rm -f "$(realpath -m "${COMPLETION_FILE}")";
    # Clean existing scripts and aliases
    clean_scripts_and_aliases;

    # Generate new scripts
    local pid;
    for pid in $(generate_scripts "$@"); do
        while test -e "/proc/${pid}"; do
            sleep 0.1;
        done
    done

    # Generate new bash completions
    generate_completions;
}

_generate "$@";
