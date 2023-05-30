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
    if [ -n "$bin" ]; then
        cat - \
          | envsubst '$NAME
                      $SRC_PATH
                      $PY_SRC
                      $PY_LIB
                      $CPP_LIB
                      $CPP_SRC
                      $CPP_DEPS
                      $CPP_ARGS
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

generate_scripts() {

    # Ensure we're in this script's directory
    cd "$( cd "$( dirname "$(realpath -m "${BASH_SOURCE[0]}")" )" && pwd )";

    local lib="${NAME:-}";

    cat ./tmpl/clone.tmpl.sh | generate_script "clone-${lib}";

    if [[ -d ~/"${lib}/.git" ]]; then

        cat ./tmpl/clean.tmpl.sh        \
          | NAME="${lib}"               \
          generate_script "clean-${lib}";

        local src="${lib}${CPP_SRC:+/$CPP_SRC}";

        local deps="$(echo -n "${CPP_DEPS:-}"                            \
          | xargs -r -d' ' -I{} bash -c                                  \
           'echo -n "-D${0%%/*}_ROOT=$(realpath -m ~/$0/build/latest) "' \
           {}                                                            \
        )";

        local args="${CPP_ARGS:-}";
        local script_name;

        for script_name in "configure" "build" "clean"; do
            cat ./tmpl/cpp-${script_name}.tmpl.sh        \
              | NAME="${lib}"                            \
                CPP_LIB="${lib}"                         \
                CPP_SRC="${src}"                         \
                CPP_DEPS="${deps}"                       \
                CPP_ARGS="${args}"                       \
              generate_script "${script_name}-${lib}-cpp";
        done

        local py_libs=($(rapids-python-pkg-names $lib));
        local py_dirs=($(rapids-python-pkg-roots $lib));

        for i in "${!py_libs[@]}"; do
            local py_dir="${py_dirs[$i]}";
            local py_lib="${py_libs[$i]}";
            for script_name in "build" "clean"; do
                cat ./tmpl/python-${script_name}.tmpl.sh  \
                  | NAME="${lib}"                         \
                    CPP_LIB="${lib}"                      \
                    CPP_SRC="${src}"                      \
                    CPP_DEPS="${deps}"                    \
                    CPP_ARGS="${args}"                    \
                    PY_SRC="${py_dir}"                    \
                    PY_LIB="${py_lib}"                    \
                  generate_script "${script_name}-${py_lib}-python";
            done

            cat ./tmpl/clean.tmpl.sh           \
              | NAME="${py_lib}"               \
              generate_script "clean-${py_lib}";
        done

        sudo find /opt/rapids-build-utils \
            \( -type d -exec chmod 0775 {} \; \
            -o -type f -exec chmod 0755 {} \; \);
    fi
}

generate_clone_scripts() {

    # Generate and install the "clone-<repo>" scripts

    set -euo pipefail;

    # Ensure we're in this script's directory
    cd "$( cd "$( dirname "$(realpath -m "${BASH_SOURCE[0]}")" )" && pwd )";

    # PS4='+ ${LINENO}: '; set -x;

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
    local repos_length="${repos_length:-0}";

    for ((i=0; i < repos_length; i++)); do

        local repo="repos_${i}";
        local name="${repo}_name";
        local path="${repo}_path";
        local cpp_args="${repo}_cpp_args";
        local cpp_sub_dir="${repo}_cpp_sub_dir";
        local cpp_depends_length="${repo}_cpp_depends_length";
        local git_repo="${repo}_git_repo";
        local git_host="${repo}_git_host";
        local git_tag="${repo}_git_tag";
        local git_upstream="${repo}_git_upstream";

        name_to_path[${!name:-}]="${!path:-}";
        name_to_cpp_sub_dir[${!name:-}]="${!cpp_sub_dir:-}";

        local cpp_depends=();

        local j=0;
        local cpp_depends_length="${!cpp_depends_length:-0}";

        for ((j=0; j < cpp_depends_length; j++)); do
            local dep="${repo}_cpp_depends_${j}";
            local dep_name="${name_to_path[${!dep}]}";
            local dep_path="${name_to_cpp_sub_dir[${!dep}]}";
            cpp_depends+=("${dep_name}${dep_path:+/$dep_path}");
        done

        NAME="${!name:-}"                 \
        SRC_PATH="${!path:-}"             \
        CPP_SRC="${!cpp_sub_dir:-}"       \
        CPP_DEPS="${cpp_depends[@]}"      \
        CPP_ARGS="${!cpp_args:-}"         \
        GIT_TAG="${!git_tag:-}"           \
        GIT_REPO="${!git_repo:-}"         \
        GIT_HOST="${!git_host:-}"         \
        GIT_UPSTREAM="${!git_upstream:-}" \
            generate_scripts;

    done

    unset name_to_path;
    unset name_to_cpp_sub_dir;
}

(remove_script_for_pattern '^clone-[\w-]+$');
(remove_script_for_pattern '^clean-[\w-]+$');
(remove_script_for_pattern '^build-[\w-]+-cpp$');
(remove_script_for_pattern '^clean-[\w-]+-cpp$');
(remove_script_for_pattern '^configure-[\w-]+-cpp$');
(remove_script_for_pattern '^build-[\w-]+-python$');
(remove_script_for_pattern '^clean-[\w-]+-python$');

(generate_clone_scripts "$@");
