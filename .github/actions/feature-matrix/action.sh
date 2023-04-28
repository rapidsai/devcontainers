#! /usr/bin/env bash

# cd to the repo root
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../../../";

join_with_delimiter() {
  local IFS='' delim=$1; shift; echo -n "$1"; shift; echo -n "${*/#/$delim}";
}

find_features_with_tests() {
  find ${@:2} -mindepth 1 -type f -name "$1" ! -wholename '*/test/_global/*' \
    -exec bash -c 'echo {} | sed -r s@features/test/\(.*\)/.*@\\1@' \;       \
  | sort | uniq                                                              ;
}

full_matrix="0";

case "${1:-}" in
   "1" | "true" ) full_matrix="1"; shift;;
   "0" | "false") full_matrix="0"; shift;;
esac

files="${@}";

features="";
scenarios="";

if [ "${full_matrix}" == "1" ] || echo "$files" | grep -q ".github/"; then
  features="$(find_features_with_tests 'test.sh' 'features/test')";
  scenarios="$(find_features_with_tests 'scenarios.json' 'features/test')";
elif echo "$files" | grep -q "features/"; then
  files="$(join_with_delimiter "\n" $files | grep "features/")";
  files="$(echo -e "$files")";
  changed=();
  for x in ${files}; do
    x="${x##features/src/}";
    x="${x##features/test/}";
    x="features/test/${x%%/*}";
    changed+=("${x}");
  done;
  changed="${changed[@]}";
  features="$(find_features_with_tests 'test.sh' ${changed})";
  scenarios="$(find_features_with_tests 'scenarios.json' ${changed})";
fi

if [[ -n "$(echo "$features")" ]]; then
  features="[\"$(join_with_delimiter '","' $features)\"]";
fi

echo "features=${features:-[]}";

if [[ -n "$(echo "$scenarios")" ]]; then
  scenarios="[\"$(join_with_delimiter '","' $scenarios)\"]";
fi

echo "scenarios=${scenarios:-[]}";
