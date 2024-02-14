#!/usr/bin/env bash

get_repos_ordered() {
    local project_manifest_yml="${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"}";
    readarray -t paths < <(yq eval '.repos[].path' "${project_manifest_yml}");
    for i in "${!paths[@]}"; do
        echo "$i ${paths[$i]}";
    done
}

get_repos() {
    local -r repos="$(get_repos_ordered)";
    join \
      <(echo "${repos}" | sort -k 1b,1)                           \
      <(find ~ -maxdepth 1 -mindepth 1 -type d ! -name '.*' -exec \
        bash -c "echo '${repos}' | grep \$(basename {})" \; \
      | sort -k 1b,1 | uniq) \
  | cut -d' ' -f3;
}

with_git_dirs() {
    cat - | xargs -r -d'\n' -I% bash -c 'if [ -d ~/%/.git ]; then echo %; fi;';
}

lib_entries() {
    local lib;
    while read -r lib; do
        cat<<EOF
{ "name": "${lib}", "path": "${lib}" }
EOF
        cpp_lib_entries "${lib}";
        python_lib_entries "${lib}";
    done;
}

cpp_lib_dirs() {
    eval "$(rapids-list-repos --repo "${1}")";

    local i=0;
    for ((i=0; i < ${repos_length:-0}; i+=1)); do
        local repo="repos_${i}";
        local repo_path="${repo}_path";
        local cpp_length="${repo}_cpp_length";

        local j=0;
        for ((j=0; j < ${!cpp_length:-0}; j+=1)); do
            local cpp_name="${repo}_cpp_${j}_name";
            local cpp_sub_dir="${repo}_cpp_${j}_sub_dir";
            echo ~/"${!repo_path:-}/${!cpp_sub_dir:-}";
        done
    done
}

# shellcheck disable=SC2016
cpp_lib_entries() {
    cpp_lib_dirs "$@"                                      \
  | xargs -r -d'\n' -I% realpath --relative-to="${HOME}" % \
  | sort -bd                                               \
  | xargs -r -d'\n' -I% bash -c 'cat<<EOF
{ "name": "${0/"$1/"/┕ }", "path": "$0" }
EOF' % "$1"
}

python_lib_entries() {
    readarray -t py_dirs < <(rapids-python-pkg-roots -r "$1" | sort -bd);
    for i in "${!py_dirs[@]}"; do
        local py_dir="${py_dirs[$i]}";
        cat<<EOF
{ "name": "${py_dir/"$1/"/┕ }", "path": "$py_dir" }
EOF
    done
}

make_vscode_workspace() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'make-vscode-workspace';

    cat<<EOF
{
  "folders": [
$(get_repos | with_git_dirs \
    | lib_entries           \
    | uniq                  \
    | xargs -r -d'\n' -I% echo -e '    %,'
)
  ],
  "settings": {
    "terminal.integrated.cwd": ""
  }
}
EOF
}

if echo "$@" | grep -qE '(\-u|\-\-update)'; then
    (make_vscode_workspace "$@" > /tmp/workspace.code-workspace);
    if ! diff -BNqw ~/workspace.code-workspace /tmp/workspace.code-workspace >/dev/null 2>&1; then
        cp /tmp/workspace.code-workspace ~/workspace.code-workspace;
    fi
    rm /tmp/workspace.code-workspace;
else
    make_vscode_workspace "$@";
fi
