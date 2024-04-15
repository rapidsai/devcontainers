#! /usr/bin/env bash

_print_usage() {
    local -;
    set -euo pipefail;

    local file="${1:-${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}}";
    if which "${file}" >/dev/null 2>&1; then
        file=$(which "${file}");
    fi

    `# optionally remove the shebang if file is a script` \
    sed -rn '0,/(#\!)?/!p' "${file}"                      \
    `# take until the end of the topmost comment`         \
  | sed -nr '1,/^[^#]?$/p'                                \
    `# strip off the leading octothorps`                  \
  | sed -r 's/^# ?//';
}

_parse_args_to_names() {
    cat -                                              \
    `# take the first char of short names i.e. -DFOO ` \
  | sed -r 's/^-([a-zA-Z0-9]{1})[^ ,*].*/\1/g'         \
    `# remove the leading --`                          \
  | sed -r 's/--?([^ ,=]+)+/\1/g'                      \
    `# translate ,| to spaces`                         \
  | sed -r 's/(,|\|)/ /g'                              \
  ;
}

_squeeze_spaces_in_options() {
    cat -                                                      \
    `# Filter for lines that start with 0-4 spaces and a dash` \
  | grep -P '^[ ]{0,4}-[^ ].*$'                                \
    `# squeeze spaces between short and long args (-f, --foo)` \
  | sed -r 's/(-[^ <(-]+,) (--[^ ]+)/\1\2/g'                   \
    ;
}

_parse_all_names_from_usage() {
    cat -                                  \
  | _squeeze_spaces_in_options             \
  | sed -rn 's/^[ ]*(--?[^ <(*]+).*$/\1/p' \
  | sed -r 's/(,|\|)/ /g'                  \
  ;
}

_parse_value_names_from_usage() {
    cat -                                                     \
  | _squeeze_spaces_in_options                                \
  | sed -rn 's/^[ ]*(--?[^ <(*]+)+[ *]*[<(](.[^)>]*).*$/\1/p' \
  | sed -r 's/(,|\|)/ /g'                                     \
  ;
}

_parse_value_types_from_usage() {
    cat -                      \
  | _squeeze_spaces_in_options \
  | sed -rn -rn 's/^[ ]*(--?[^ <(*]+)+[ *]*([<(].[^)>]*)([)>]).*$/\2\3/p';
}

_parse_bool_names_from_usage() {
    # bool names are the complement of `all names` \ `value names`
    tee >(_parse_all_names_from_usage | sort -su)   \
        >(_parse_value_names_from_usage | sort -su) \
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
  | sed -r 's/([ ]?--[^ ,=]+)+,?//g'        \
  | _listify                                \
    ;
}

_parse_short_names() {
    cat -                                   \
  `# skip the long opts`                    \
  | _take_short_opts                        \
  `# remove the leading -`                  \
  | sed -r 's/-([^ ,*]+)+[,*]?/\1/g'        \
  `# take the first character`              \
  | sed -e 's/^\(.\{1\}\).*/\1/'            \
    ;
}

_parse_long_names() {
    # long opts are the complement of `all opts` \ `short opts`
    tee >(_listify)               \
        >(_take_short_opts)       \
        1>/dev/null               \
  | sort -s                       \
  | uniq -u                       \
  `# remove the leading --`       \
  | sed -r 's/--?([^ ,=]+)+/\1/g' \
  | _listify                      \
    ;
}

_parse_aliases() {
    cat -                           \
  | _parse_args_to_names            \
  | while read -r aliases; do
        local -a ary="(${aliases})";
        echo "[${ary[0]}]=\"${ary[*]:1}\"";
    done
}

if [ "$(basename "${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}")" = parse-args-from-docstring.sh ] \
|| [ "$(basename "${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}")" = devcontainer-utils-parse-args-from-docstring ]; then
    if test $# -gt 0; then
        _print_usage "$@";
    fi
fi
