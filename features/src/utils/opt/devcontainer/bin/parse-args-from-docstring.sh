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

parse_all_names_from_usage() {
    cat - \
  | sed -rn 's/^([ ]*)(--?[^*][^ *]+|,|_)+(.*)$/\2/p' \
  | sed -r 's/(,|\|)/ /g' \
  ;
}

parse_bool_names_from_usage() {
    cat - \
  | sed -rn 's/^([ ]*)(--?[^ ]+|,|_)+([^<(]*)$/\2/p' \
  | sed -r 's/(,|\|)/ /g';
}

parse_value_names_from_usage() {
    cat - \
  | sed -rn 's/^([ ]*)(--?[^ \*]+|,|_)+[ ]*[<(](.[^)>]*).*$/\2/p' \
  | sed -r 's/(,|\|)/ /g';
}

parse_value_types_from_usage() {
    cat - \
  | sed -rn 's/^[ ]*(--?[^ \*]+|,|_)+[ ]*([<(].[^)>]*)([)>]).*$/\2\3/p';
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
