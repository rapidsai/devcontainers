#! /usr/bin/env bash

get_repos_ordered() {
    local names=($(yq eval '.repos[].name' /opt/rapids-build-utils/manifest.yaml));
    for i in "${!names[@]}"; do
        echo "$i ${names[$i]}";
    done
}

get_repos() {
    local repos="$(get_repos_ordered)";

    join \
      <(echo "${repos}")                                          \
      <(find ~ -maxdepth 1 -mindepth 1 -type d ! -name '.*' -exec \
        bash -c "echo '${repos}' | grep \$(basename {})" \; \
      | sort -h | uniq) \
  | cut -d' ' -f3;
}

with_git_dirs() {
    cat - | xargs -r -d'\n' -I% bash -c 'if [ -d ~/%/.git ]; then echo %; fi;';
}

lib_entries() {
    local lib;
    while read lib; do
        cat<<EOF
{ "name": "$lib", "path": "$lib" }
EOF
        cpp_lib_entries $lib;
        python_lib_entries $lib;
    done;
}

cpp_lib_entries() {
    local dir=~/"$1";
    find "$dir"                                        \
      -maxdepth 2 -type f                              \
      -name CMakeLists.txt                             \
      -exec dirname {} \;                              \
`# substitute for "head -n1" that doesn't close stdin` \
`#  | sed -n "1,1p"`                                   \
  | grep -vE "^${dir}$"                                \
  | xargs -r -d'\n' -I% realpath --relative-to=$HOME % \
  | sort -bd                                           \
  | xargs -r -d'\n' -I% bash -c 'cat<<EOF
{ "name": "${0/"$1/"/┕ }", "path": "$0" }
EOF' % $1
}

python_lib_entries() {
    local py_dirs=($(rapids-python-pkg-roots $1 | sort -bd));
    for i in "${!py_dirs[@]}"; do
        local py_dir="${py_dirs[$i]}";
        cat<<EOF
{ "name": "${py_dir/"$1/"/┕ }", "path": "$py_dir" }
EOF
    done
}

make_vscode_workspace() {
    set -euo pipefail;

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
    (make_vscode_workspace "$@");
fi
