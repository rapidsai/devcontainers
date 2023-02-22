#! /usr/bin/env -S bash -euo pipefail

remove_script_for_pattern() {
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

        local src="${lib}${CPP_SRC:+/$CPP_SRC}";

        local deps="$(echo -n "${CPP_DEPS:-}"                           \
          | xargs -r -d' ' -I{} bash -c '                               \
            echo -n "-D${0%%/*}_ROOT=$(realpath -m ~/$0/build/latest) " \
            ' {}                                                        \
        )";

        local args="${CPP_ARGS:-}";

        cat ./tmpl/cpp-build.tmpl.sh        \
          | NAME="${lib}"                   \
            CPP_LIB="${lib}"                \
            CPP_SRC="${src}"                \
            CPP_DEPS="${deps}"              \
            CPP_ARGS="${args}"              \
          generate_script "build-${lib}-cpp";

        cat ./tmpl/cpp-configure.tmpl.sh        \
          | NAME="${lib}"                       \
            CPP_LIB="${lib}"                    \
            CPP_SRC="${src}"                    \
            CPP_DEPS="${deps}"                  \
            CPP_ARGS="${args}"                  \
          generate_script "configure-${lib}-cpp";

        local py_libs=($(rapids-python-pkg-names $lib));
        local py_dirs=($(rapids-python-pkg-roots $lib));

        for i in "${!py_libs[@]}"; do
            local py_dir="${py_dirs[$i]}";
            local py_lib="${py_libs[$i]}";
            cat ./tmpl/python-build.tmpl.sh           \
              | NAME="${lib}"                         \
                CPP_LIB="${lib}"                      \
                CPP_SRC="${src}"                      \
                CPP_DEPS="${deps}"                    \
                CPP_ARGS="${args}"                    \
                PY_SRC="${py_dir}"                    \
                PY_LIB="${py_lib}"                    \
              generate_script "build-${py_lib}-python";
        done

        sudo find /opt/rapids-build-utils \
            \( -type d -exec chmod 0775 {} \; \
            -o -type f -exec chmod 0755 {} \; \);
    fi
}

generate_clone_scripts() {
    # Ensure we're in this script's directory
    cd "$( cd "$( dirname "$(realpath -m "${BASH_SOURCE[0]}")" )" && pwd )";

    # Generate and install the "clone-<repo>" scripts
    local manifest="$(cat /opt/rapids-build-utils/manifest.yaml)";
    local names=($(echo -e "$manifest" | yq '.repos[].name'));

    local cpp_build_dirs=();

    declare -A name_to_path;
    declare -A name_to_cpp_sub_dir;

    for i in "${!names[@]}"; do
        local name="${names[$i]}";
        local path="$(         echo -e "$manifest" | yq ".repos | map(select(.name == \"${name}\") | .path)         | flatten | join(\" \")")";
        local cpp_args="$(     echo -e "$manifest" | yq ".repos | map(select(.name == \"${name}\") | .cpp.args)     | flatten | join(\" \")")";
        local cpp_sub_dir="$(  echo -e "$manifest" | yq ".repos | map(select(.name == \"${name}\") | .cpp.sub_dir)  | flatten | join(\" \")")";
        local cpp_depends="$(  echo -e "$manifest" | yq ".repos | map(select(.name == \"${name}\") | .cpp.depends)  | flatten | join(\" \")")";
        local git_tag="$(      echo -e "$manifest" | yq ".repos | map(select(.name == \"${name}\") | .git.tag)      | flatten | join(\" \")")";
        local git_repo="$(     echo -e "$manifest" | yq ".repos | map(select(.name == \"${name}\") | .git.repo)     | flatten | join(\" \")")";
        local git_host="$(     echo -e "$manifest" | yq ".repos | map(select(.name == \"${name}\") | .git.host)     | flatten | join(\" \")")";
        local git_upstream="$( echo -e "$manifest" | yq ".repos | map(select(.name == \"${name}\") | .git.upstream) | flatten | join(\" \")")";

        name_to_path[$name]="$path";
        name_to_cpp_sub_dir[$name]="$cpp_sub_dir";
        cpp_build_dirs+=(~/"${path}${cpp_sub_dir:+/$cpp_sub_dir}/build/latest");

        local depends=();

        for dep in ${cpp_depends}; do
            local dep_name="${name_to_path[$dep]}";
            local dep_path="${name_to_cpp_sub_dir[$dep]}";
            depends+=("${dep_name}${dep_path:+/$dep_path}");
        done

        NAME="${name}"                 \
        SRC_PATH="${path}"             \
        CPP_SRC="${cpp_sub_dir}"       \
        CPP_DEPS="${depends[@]}"       \
        CPP_ARGS="${cpp_args}"         \
        GIT_TAG="${git_tag}"           \
        GIT_REPO="${git_repo}"         \
        GIT_HOST="${git_host}"         \
        GIT_UPSTREAM="${git_upstream}" \
            generate_scripts;
    done

    cat <<EOF | sudo tee /etc/ld.so.conf.d/dev-libs.conf >/dev/null
$(for dir in ${cpp_build_dirs[@]}; do echo -e "$dir\n$dir/lib\n$dir/lib64"; done)
EOF

    sudo ldconfig;

    unset name_to_path;
    unset name_to_cpp_sub_dir;
}

remove_script_for_pattern '^clone-[\w-]+'         ;
remove_script_for_pattern '^build-[\w-]+-cpp'     ;
remove_script_for_pattern '^configure-[\w-]+-cpp' ;
remove_script_for_pattern '^build-[\w-]+-python'  ;

generate_clone_scripts;
