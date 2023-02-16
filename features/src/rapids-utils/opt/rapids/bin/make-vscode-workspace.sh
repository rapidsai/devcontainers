#! /usr/bin/env -S bash -euo pipefail

get_repos_ordered() {
    local cmd="${@}";
    cat<<EOF | ${cmd:-cat -}
01 rmm
02 cudf
03 raft
04 cumlprims_mg
05 cuml
06 cugraph-ops
07 cugraph
08 cuspatial
EOF
}

get_repos() {

    export -f get_repos_ordered;

    join \
      <(get_repos_ordered)                                       \
      <(find ~ -maxdepth 1 -mindepth 1 -type d ! -name '.*'      \
        -exec bash -c 'get_repos_ordered grep $(basename {})' \; \
      | sort -h) \
  | cut -d' ' -f3;

    export -n get_repos_ordered;
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
        cpp_lib_entry $lib;
        python_lib_entries $lib;
    done;
}

cpp_lib_entry() {
    local dir=~/"$1";
    find "$dir"                                        \
      -maxdepth 2 -type f                              \
      -name CMakeLists.txt                             \
      -exec dirname {} \;                              \
`# substitute for "head -n1" that doesn't close stdin` \
  | sed -n "1,1p"                                      \
  | grep -vE "^${dir}$"                                \
  | xargs -r -d'\n' -I% realpath --relative-to=$HOME % \
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
    cat<<EOF
{
  "folders": [
    { "name": ".conda", "path": ".conda" },
    { "name": ".config", "path": ".config" },
    { "name": ".cache", "path": ".cache" },
$(get_repos | with_git_dirs \
    | lib_entries \
    | xargs -r -d'\n' -I% echo -e '    %,'
)
  ],
  "settings": {
    "terminal.integrated.cwd": ""
  }
}
EOF
}

make_vscode_workspace "$@";
