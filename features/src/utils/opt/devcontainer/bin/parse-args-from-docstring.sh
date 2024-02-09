#! /usr/bin/env bash

print_usage() {
    local -;
    set -euo pipefail;
    local file="${1:-${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}}";
    if which "${file}"; then file=$(which "${file}"); fi
    sed -n '2,/^$/p' "${file}" | sed -r 's/^# ?//';
}

parse_args_to_names() {
    cat - \
  | sed -r 's/--?([^ ,]+)+/\1/g'    \
  | sed -r 's/(,|\|)/ /g'           \
  ;
}

_squeeze_spaces_in_options() {
    cat - \
    `# Filter for lines that start with 0-4 spaces and a dash` \
  | grep -P '^[ ]{0,4}-[^ ].*$'                                \
    `# squeeze spaces between short and long args (-f, --foo)` \
  | sed -r 's/(-[^ <(-]+,) (--[^ ]+)/\1\2/g'                   \
    ;
}

parse_all_names_from_usage() {
    cat - \
  | _squeeze_spaces_in_options \
  | sed -rn 's/^[ ]*(--?[^ *]+)+[^*]*$/\1/p' \
  | sed -r 's/(,|\|)/ /g' \
  ;
}

parse_value_names_from_usage() {
    cat - \
  | _squeeze_spaces_in_options \
  | sed -rn 's/^([ ]*)(--?[^ \*]+|,|_)+[ ]*[<(](.[^)>]*).*$/\2/p' \
  | sed -r 's/(,|\|)/ /g';
}

parse_value_types_from_usage() {
    cat - \
  | _squeeze_spaces_in_options \
  | sed -rn 's/^[ ]*(--?[^ \*]+|,|_)+[ ]*([<(].[^)>]*)([)>]).*$/\2\3/p';
}

parse_bool_names_from_usage() {
    # bool names are the complement of `all names` \ `value names`
    tee >(parse_all_names_from_usage)   \
        >(parse_value_names_from_usage) \
        1>/dev/null                     \
  | sort -s                             \
  | uniq -u                             \
  | sed -r 's/(,|\|)/ /g'               \
    ;
}

_listify() {
    cat -                                   \
  `# trim whitespace`                       \
  | tr -s '[:space:]'                       \
  `# replace spaces with pipes`             \
  | tr '[:space:]' '|'                      \
  | rev | cut -d'|' -f1 --complement | rev  \
  `# replace pipes with newlines`           \
  | tr '|' '\n'                             \
  | grep -v -e '^$'                         \
  | sort -su                                \
    ;
}

_take_short_opts() {
    cat -                                   \
  `# skip the long opts`                    \
  | sed -r 's/([ ]?--[^ ,]+)+,?//g'         \
  | _listify                                \
    ;
}

parse_short_names() {
    cat -                                   \
  `# skip the long opts`                    \
  | _take_short_opts                        \
  `# remove the leading -`                  \
  | sed -r 's/-([^ ,\*]+)+[,\*]?/\1/g'      \
    ;
}

parse_long_names() {
    # long opts are the complement of `all opts` \ `short opts`
    tee >(_listify)              \
        >(_take_short_opts)      \
        1>/dev/null              \
  | sort -s                      \
  | uniq -u                      \
  `# remove the leading --`      \
  | sed -r 's/--?([^ ,]+)+/\1/g' \
  | _listify                     \
    ;
}

parse_aliases() {
    cat -                           \
  | parse_args_to_names             \
  | while read -r aliases; do
        local -a ary="(${aliases})";
        echo "[${ary[0]}]=\"${ary[*]:1}\"";
    done
}
