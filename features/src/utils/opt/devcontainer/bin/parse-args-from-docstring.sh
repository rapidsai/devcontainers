#! /usr/bin/env bash

print_usage() {
    sed -n '2,/^$/p' "$(which "${1:-${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}}")" | sed -r 's/^# ?//';
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
  | sed -rn 's/^([ ]*)(--?[^*][^ *]+|,|_)+(.*)$/\2/p' \
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
    tee >(parse_all_names_from_usage)   \
        >(parse_value_names_from_usage) \
        1>/dev/null \
  | sort -s         \
  | uniq -u         \
  | sed -r 's/(,|\|)/ /g';
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
    ;
}

parse_short_names() {
    cat -                                   \
  `# skip the long opts`                    \
  | sed -r 's/([ ]?--[^ ,]+)+,?//g'         \
  `# take the short opts`                   \
  | sed -r 's/-([^ ,\*]+)+[,\*]?/\1/g'      \
  | _listify;
}

parse_long_names() {
    cat -                                        \
  `# take the long opts`                         \
  | sed -r 's/(-[^ ,\*]+)?[ ]?(--[^,]+)+,?/\2/g' \
  `# remove the leading --`                      \
  | sed -r 's/--?([^ ,]+)+/\1/g'                 \
  | _listify;
}

parse_aliases() {
    cat -                           \
  | parse_args_to_names             \
  | while read -r aliases; do
        local -a ary="(${aliases})";
        echo "[${ary[0]}]=\"${ary[*]:1}\"";
    done
}
