#! /usr/bin/env bash

TMPL=/opt/rapids-build-utils/bin/tmpl;

TMP_SCRIPT_DIR=/tmp/rapids-build-utils
mkdir -p $TMP_SCRIPT_DIR

clean_scripts() {
    set -euo pipefail;
    for x in $(find $TMP_SCRIPT_DIR -maxdepth 1 -type f -printf '%f\n'); do
        (sudo update-alternatives --remove-all $x > /dev/null 2>&1);
    done
    sudo rm -rf "$TMP_SCRIPT_DIR";
    mkdir -p $TMP_SCRIPT_DIR
}

generate_script() {
    local bin="${1:-}";
    if test -n "$bin" && ! test -f "$TMP_SCRIPT_DIR/${bin}"; then
        (
        cat - \
      | envsubst '$NAME
                  $SRC_PATH
                  $PY_SRC
                  $PY_LIB
                  $CPP_LIB
                  $CPP_SRC
                  $CPP_ARGS
                  $CPP_DEPS
                  $GIT_TAG
                  $GIT_REPO
                  $GIT_HOST
                  $GIT_UPSTREAM' \
      | sudo tee "$TMP_SCRIPT_DIR/${bin}" >/dev/null;

        sudo chmod +x "$TMP_SCRIPT_DIR/${bin}";

        sudo update-alternatives --install \
            "/usr/bin/${bin}" "${bin}" "$TMP_SCRIPT_DIR/${bin}" 0 \
            >/dev/null 2>&1;
        ) & true;

        echo "$!"
    fi
}

generate_all_script_impl() {
    local bin="$SCRIPT-all";
    if test -n "$bin" && ! test -f "$TMP_SCRIPT_DIR/${bin}"; then
        (
        cat - \
      | envsubst '$NAMES
                  $SCRIPT' \
      | sudo tee "$TMP_SCRIPT_DIR/${bin}" >/dev/null;

        sudo chmod +x "$TMP_SCRIPT_DIR/${bin}";

        sudo update-alternatives --install \
            "/usr/bin/${bin}" "${bin}" "$TMP_SCRIPT_DIR/${bin}" 0 \
            >/dev/null 2>&1;
        ) & true;

        echo "$!"
    fi
}

generate_all_script() {
    (
        cat ${TMPL}/all.tmpl.sh      \
      | generate_all_script_impl;
    ) || true;
}

generate_clone_script() {
    (
        cat ${TMPL}/clone.tmpl.sh      \
      | generate_script "clone-${NAME}";
    ) || true;
}

generate_repo_scripts() {
    local script_name;
    for script_name in "configure" "build" "clean"; do (
        cat ${TMPL}/${script_name}.tmpl.sh     \
      | generate_script "${script_name}-${NAME}";
    ) || true;
    done
}

generate_cpp_scripts() {
    local script_name;
    for script_name in "configure" "build" "clean"; do (
        cat ${TMPL}/cpp-${script_name}.tmpl.sh         \
      | CPP_SRC="${SRC_PATH:-}${CPP_SRC:+/$CPP_SRC}"   \
        generate_script "${script_name}-${CPP_LIB}-cpp";
    ) || true;
    done
}

generate_python_scripts() {
    local script_name;
    for script_name in "build" "clean"; do (
        cat ${TMPL}/python-${script_name}.tmpl.sh        \
      | generate_script "${script_name}-${PY_LIB}-python";
    ) || true;
    done
    for script_name in "inplace" "dist"; do (
        cat ${TMPL}/python-build-${script_name}.tmpl.sh        \
      | generate_script "build-${PY_LIB}-python-${script_name}";
    ) || true;
    done
    cat ${TMPL}/python-wheel.tmpl.sh       \
  | generate_script "build-${PY_LIB}-wheel";
}

generate_scripts() {

    # Generate and install the "clone-<repo>" scripts

    set -euo pipefail;

    # Ensure we're in this script's directory
    cd "$( cd "$( dirname "$(realpath -m "${BASH_SOURCE[0]}")" )" && pwd )";

    # PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;

    eval "$(                                  \
        rapids-list-repos "$@"                \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    declare -A cpp_name_to_path;

    local i;
    local j;
    local k;

    local repo_name_all=()

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_name="${repo}_name";
        local repo_path="${repo}_path";
        local cpp_length="${repo}_cpp_length";
        local py_length="${repo}_python_length";
        local git_repo="${repo}_git_repo";
        local git_host="${repo}_git_host";
        local git_tag="${repo}_git_tag";
        local git_upstream="${repo}_git_upstream";

        repo_name="$(tr "[:upper:]" "[:lower:]" <<< "${!repo_name:-}")";

        repo_name_all+=($repo_name)

        # Generate a clone script for each repo
        (
            NAME="${repo_name:-}"             \
            SRC_PATH="${!repo_path:-}"        \
            GIT_TAG="${!git_tag:-}"           \
            GIT_REPO="${!git_repo:-}"         \
            GIT_HOST="${!git_host:-}"         \
            GIT_UPSTREAM="${!git_upstream:-}" \
            generate_clone_script             ;
        ) || true;

        if [[ -d ~/"${!repo_path:-}/.git" ]]; then

            local cpp_libs=();
            local cpp_dirs=();

            for ((j=0; j < ${!cpp_length:-0}; j+=1)); do

                local cpp_name="${repo}_cpp_${j}_name";
                local cpp_args="${repo}_cpp_${j}_args";
                local cpp_sub_dir="${repo}_cpp_${j}_sub_dir";
                local cpp_depends_length="${repo}_cpp_${j}_depends_length";
                local cpp_path="${!repo_path:-}${!cpp_sub_dir:+/${!cpp_sub_dir}}";

                cpp_dirs+=("${cpp_path}");
                cpp_libs+=("${!cpp_name:-}");
                cpp_name="$(tr "[:upper:]" "[:lower:]" <<< "${!cpp_name:-}")";

                cpp_name_to_path["${cpp_name:-}"]="${cpp_path}";

                local deps=();

                for ((k=0; k < ${!cpp_depends_length:-0}; k+=1)); do
                    local dep="${repo}_cpp_${j}_depends_${k}";
                    local dep_cpp_name=$(tr "[:upper:]" "[:lower:]" <<< "${!dep}");
                    if ! test -v cpp_name_to_path["${dep_cpp_name}"]; then
                        continue;
                    fi
                    local dep_cpp_path="${cpp_name_to_path["${dep_cpp_name}"]}";

                    deps+=(-D${!dep}_ROOT=\"$(realpath -m ~/${dep_cpp_path}/build/latest)\");
                    deps+=(-D$(tr "[:upper:]" "[:lower:]" <<< "${!dep}")_ROOT=\"$(realpath -m ~/${dep_cpp_path}/build/latest)\");
                    deps+=(-D$(tr "[:lower:]" "[:upper:]" <<< "${!dep}")_ROOT=\"$(realpath -m ~/${dep_cpp_path}/build/latest)\");
                done

                (
                    SRC_PATH="${!repo_path:-}"  \
                    CPP_LIB="${cpp_name:-}"     \
                    CPP_SRC="${!cpp_sub_dir:-}" \
                    CPP_ARGS="${!cpp_args:-}"   \
                    CPP_DEPS="${deps[@]}"       \
                    generate_cpp_scripts        ;
                ) || true;
            done

            local args=();
            local deps=();

            for ((k=0; k < ${#cpp_libs[@]}; k+=1)); do
                # Define both lowercase and uppercase
                # `-DFIND_<lib>_CPP=ON` and `-DFIND_<LIB>_CPP=ON` because the RAPIDS
                # scikit-build CMakeLists.txt's aren't 100% consistent in the casing
                local cpp_dir="${cpp_dirs[$k]}";
                local cpp_lib="${cpp_libs[$k]}";
                args+=(-DFIND_${cpp_lib}_CPP=ON);
                args+=(-DFIND_$(tr "[:upper:]" "[:lower:]" <<< "${cpp_lib}")_CPP=ON);
                args+=(-DFIND_$(tr "[:lower:]" "[:upper:]" <<< "${cpp_lib}")_CPP=ON);
                deps+=(-D${cpp_lib}_ROOT=\"$(realpath -m ~/${cpp_dir}/build/latest)\");
                deps+=(-D$(tr "[:upper:]" "[:lower:]" <<< "${cpp_lib}")_ROOT=\"$(realpath -m ~/${cpp_dir}/build/latest)\");
                deps+=(-D$(tr "[:lower:]" "[:upper:]" <<< "${cpp_lib}")_ROOT=\"$(realpath -m ~/${cpp_dir}/build/latest)\");
            done

            local py_libs=()
            local py_dirs=()

            for ((j=0; j < ${!py_length:-0}; j+=1)); do
                local py_name="${repo}_python_${j}_name";
                local py_args="${repo}_python_${j}_args";
                local py_sub_dir="${repo}_python_${j}_sub_dir";
                local py_depends_length="${repo}_python_${j}_depends_length";
                local py_path="${!repo_path:-}${!py_sub_dir:+/${!py_sub_dir}}";

                py_libs+=(${!py_name})
                py_dirs+=($py_path)
            done;

            for ((k=0; k < ${#py_libs[@]}; k+=1)); do
                local py_dir="${py_dirs[$k]}";
                local py_lib="${py_libs[$k]}";
                (
                    PY_SRC="${py_dir}"     \
                    PY_LIB="${py_lib}"     \
                    CPP_ARGS="${args[@]}"  \
                    CPP_DEPS="${deps[@]}"  \
                    generate_python_scripts;
                ) || true;
            done

            for ((k=0; k < ${#cpp_libs[@]}; k+=1)); do
                cpp_libs[$k]="$(tr "[:upper:]" "[:lower:]" <<< "${cpp_libs[$k]}")";
            done

            (
                NAME="${repo_name:-}"    \
                PY_LIB="${py_libs[@]}"   \
                CPP_LIB="${cpp_libs[@]}" \
                generate_repo_scripts    ;
            ) || true;
        fi
    done

    sudo find /opt/rapids-build-utils \
        \( -type d -exec chmod 0775 {} \; \
        -o -type f -exec chmod 0755 {} \; \);

    unset cpp_name_to_path;

    for script in "clone" "clean" "configure" "build"; do
        # Generate a script to run a script for all repos
        (
            NAMES="${repo_name_all[@]}"       \
            SCRIPT="${script}"                \
            generate_all_script               ;
        ) || true;
    done;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(clean_scripts);

for pid in $(generate_scripts "$@"); do
    while [[ -e "/proc/$pid" ]]; do
        sleep 0.1
    done
done