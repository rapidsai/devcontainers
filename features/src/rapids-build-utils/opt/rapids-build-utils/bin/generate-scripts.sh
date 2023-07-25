#! /usr/bin/env bash

remove_script_for_pattern() {
    set -euo pipefail;

    local pattern="${1}";
    for x in $(update-alternatives --get-selections | grep -oP "$pattern"); do
        if [[ -f "$(which "$x")" ]]; then
            (sudo rm "$(realpath -m "$(which "$x")")" >/dev/null 2>&1 || true);
            (sudo update-alternatives --remove-all $x >/dev/null 2>&1 || true);
        fi
    done
}

generate_script() {
    local bin="${1:-}";
    if test -n "$bin" && ! test -f "/tmp/${bin}.sh"; then
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
      | sudo tee "/tmp/${bin}.sh" >/dev/null;

        sudo chmod +x "/tmp/${bin}.sh";

        sudo update-alternatives --install \
            "/usr/bin/${bin}" "${bin}" "/tmp/${bin}.sh" 0 \
            >/dev/null 2>&1;
    fi
}

generate_clone_script() {

    # Ensure we're in this script's directory
    cd "$( cd "$( dirname "$(realpath -m "${BASH_SOURCE[0]}")" )" && pwd )";

    local lib="${NAME:-}";

    (
        cat ./tmpl/clone.tmpl.sh      \
      | generate_script "clone-${lib}";
    ) || true;
}

generate_repo_scripts() {

    # Ensure we're in this script's directory
    cd "$( cd "$( dirname "$(realpath -m "${BASH_SOURCE[0]}")" )" && pwd )";

    local lib="${NAME:-}";
    local path="${SRC_PATH:-}";

    (
        cat ./tmpl/clean.tmpl.sh      \
      | NAME="${lib}"                 \
        generate_script "clean-${lib}";
    ) || true;
}

generate_cpp_scripts() {

    # Ensure we're in this script's directory
    cd "$( cd "$( dirname "$(realpath -m "${BASH_SOURCE[0]}")" )" && pwd )";

    local lib="${NAME:-}";
    local path="${SRC_PATH:-}";

    local src="${path}${CPP_SRC:+/$CPP_SRC}";

    local args="${CPP_ARGS:-}";

    local deps="$(echo -n "${CPP_DEPS:-}"                                \
      | xargs -r -d' ' -I{} bash -c                                      \
       'echo -n "-D${0%%/*}_ROOT=\"$(realpath -m ~/$0/build/latest)\" "' \
       {}                                                                \
    )";

    local script_name;

    for script_name in "configure" "build" "clean"; do
        (
            cat ./tmpl/cpp-${script_name}.tmpl.sh      \
          | NAME="${lib}"                              \
            CPP_LIB="${lib}"                           \
            CPP_SRC="${src}"                           \
            CPP_ARGS="${args}"                         \
            CPP_DEPS="${deps}"                         \
            generate_script "${script_name}-${lib}-cpp";
        ) || true;
    done

    unset script_name;
}

generate_python_scripts() {

    # Ensure we're in this script's directory
    cd "$( cd "$( dirname "$(realpath -m "${BASH_SOURCE[0]}")" )" && pwd )";

    local lib="${NAME:-}";
    local path="${SRC_PATH:-}";

    local script_name;

    local py_libs=($(rapids-python-pkg-names "$path"));
    local py_dirs=($(rapids-python-pkg-roots "$path"));

    for i in "${!py_libs[@]}"; do
        local py_dir="${py_dirs[$i]}";
        local py_lib="${py_libs[$i]}";
        for script_name in "build" "clean"; do
            (
                cat ./tmpl/python-${script_name}.tmpl.sh         \
              | NAME="${lib}"                                    \
                CPP_LIB="${lib}"                                 \
                CPP_ARGS="${CPP_ARGS}"                           \
                CPP_DEPS="${CPP_DEPS}"                           \
                PY_SRC="${py_dir}"                               \
                PY_LIB="${py_lib}"                               \
                generate_script "${script_name}-${py_lib}-python";
            ) || true;
        done

        (
            cat ./tmpl/clean.tmpl.sh         \
          | NAME="${py_lib}"                 \
            generate_script "clean-${py_lib}";
        ) || true;
    done

    unset script_name;
}

generate_scripts() {

    # Generate and install the "clone-<repo>" scripts

    set -euo pipefail;

    # Ensure we're in this script's directory
    cd "$( cd "$( dirname "$(realpath -m "${BASH_SOURCE[0]}")" )" && pwd )";

    # PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;

    local project_manifest_yml="${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"}";

    eval "$(
        yq -Mo json "${project_manifest_yml}" \
      | jq -r "$(cat <<"________EOF" | tr -s '[:space:]'
        [
          paths(arrays) as $path | {
            "key": ($path + ["length"]) | join("_"),
            "val": getpath($path) | length
          }
        ] + [
          paths(scalars) as $path | {
            "key": $path | join("_"),
            "val": getpath($path)
          }
        ]
        | map(select(.key | startswith("repos")))
        | map("local " + .key + "=" + (.val | @sh))[]
________EOF
)")";

    declare -A name_to_path;
    declare -A name_to_cpp_sub_dir;

    local i=0;

    for ((i=0; i < ${repos_length:-0}; i+=1)); do

        local repo="repos_${i}";
        local repo_name="${repo}_name";
        local repo_path="${repo}_path";
        local cpp_length="${repo}_cpp_length";
        local git_repo="${repo}_git_repo";
        local git_host="${repo}_git_host";
        local git_tag="${repo}_git_tag";
        local git_upstream="${repo}_git_upstream";

        name_to_path[${!repo_name:-}]="${!repo_path:-}";

        # Generate a clone script for each repo
        (
            NAME="${!repo_name:-}"            \
            SRC_PATH="${!repo_path:-}"        \
            GIT_TAG="${!git_tag:-}"           \
            GIT_REPO="${!git_repo:-}"         \
            GIT_HOST="${!git_host:-}"         \
            GIT_UPSTREAM="${!git_upstream:-}" \
            generate_clone_script             ;
        ) || true;

        if [[ -d ~/"${!repo_path:-}/.git" ]]; then (
            NAME="${!repo_name:-}"     \
            SRC_PATH="${!repo_path:-}" \
            generate_repo_scripts      ;
        ) || true;
        fi

        local cpp_libs=();
        local cpp_dirs=();

        local j=0;

        for ((j=0; j < ${!cpp_length:-0}; j+=1)); do

            local cpp_name="${repo}_cpp_${j}_name";
            local cpp_args="${repo}_cpp_${j}_args";
            local cpp_sub_dir="${repo}_cpp_${j}_sub_dir";
            local cpp_depends_length="${repo}_cpp_${j}_depends_length";

            cpp_libs+=("${!cpp_name:-}");
            cpp_dirs+=("${!repo_path:-}/${!cpp_sub_dir:-}");

            name_to_cpp_sub_dir[${!cpp_name:-}]="${!cpp_sub_dir:-}";

            local cpp_depends=();

            local k=0;

            for ((k=0; k < ${!cpp_depends_length:-0}; k+=1)); do
                local dep="${repo}_cpp_${j}_depends_${k}";
                local dep_name="${name_to_path[${!dep}]}";
                local dep_path="${name_to_cpp_sub_dir[${!dep}]}";
                cpp_depends+=("${dep_name}${dep_path:+/$dep_path}");
            done

            if [[ -d ~/"${!repo_path:-}/.git" ]]; then (
                NAME="${!cpp_name:-}"             \
                SRC_PATH="${!repo_path:-}"        \
                CPP_SRC="${!cpp_sub_dir:-}"       \
                CPP_ARGS="${!cpp_args:-}"         \
                CPP_DEPS="${cpp_depends[@]}"      \
                generate_cpp_scripts              ;
            ) || true;
            fi
        done

        if [[ -d ~/"${!repo_path:-}/.git" ]]; then (

            local args=();
            local deps=();
            local k=0;

            for k in "${!cpp_libs[@]}"; do
                # Define both lowercase and uppercase
                # `-DFIND_<lib>_CPP=ON` and `-DFIND_<LIB>_CPP=ON` because the RAPIDS
                # scikit-build CMakeLists.txt's aren't 100% consistent in the casing
                local cpp_dir="${cpp_dirs[$k]}";
                local cpp_lib="${cpp_libs[$k]}";
                args+=(-DFIND_$(tr "[:upper:]" "[:lower:]" <<< "${cpp_lib}")_CPP=ON);
                args+=(-DFIND_$(tr "[:lower:]" "[:upper:]" <<< "${cpp_lib}")_CPP=ON);
                deps+=(-D$(tr "[:upper:]" "[:lower:]" <<< "${cpp_lib}")_ROOT=\"$(realpath -m ~/${cpp_dir}/build/latest)\");
                deps+=(-D$(tr "[:lower:]" "[:upper:]" <<< "${cpp_lib}")_ROOT=\"$(realpath -m ~/${cpp_dir}/build/latest)\");
            done

            NAME="${!repo_name:-}"      \
            SRC_PATH="${!repo_path:-}"  \
            CPP_ARGS="${args[@]}"       \
            CPP_DEPS="${deps[@]}"       \
            generate_python_scripts     ;
        ) || true;
        fi
    done

    sudo find /opt/rapids-build-utils \
        \( -type d -exec chmod 0775 {} \; \
        -o -type f -exec chmod 0755 {} \; \);

    unset name_to_path;
    unset name_to_cpp_sub_dir;
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(remove_script_for_pattern '^clone-[\w-_]+');
(remove_script_for_pattern '^clean-[\w-_]+');
(remove_script_for_pattern '^build-[\w-_]+-cpp');
(remove_script_for_pattern '^clean-[\w-_]+-cpp');
(remove_script_for_pattern '^configure-[\w-_]+-cpp');
(remove_script_for_pattern '^build-[\w-_]+-python');
(remove_script_for_pattern '^clean-[\w-_]+-python');

(generate_scripts "$@");
