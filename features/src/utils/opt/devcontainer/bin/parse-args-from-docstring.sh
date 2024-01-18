#! /usr/bin/env bash

if test -n "${devcontainer_utils_debug:-}" \
&& ( test -z "${devcontainer_utils_debug##*"all"*}" \
  || test -z "${devcontainer_utils_debug##*"parse-args"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

print_usage() {
    sed -n '2,/^$/p' "${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}" | sed -r 's/^# ?//';
}

parse_names_from_usage() {
    cat - \
  | sed -rn 's/^([ ]*)(--?[^ ]+|,|_|\*)+(.*)$/\2/p' \
  | sed -r 's/--?([^ ,]+)+,?/\1|/g' \
  | sed -r 's/\*/\\*/g';
}

parse_bool_names_from_usage() {
    cat - \
  | sed -rn 's/^([ ]*)(--?[^ ]+|,|_)+([^<]*)$/\2/p' \
  | sed -r 's/(,|\|)/ /g';
}

parse_value_names_from_usage() {
    cat - \
  | sed -rn 's/^([ ]*)(--?[^ \*]+|,|_)+[ ]*<(.[^>]*).*$/\2/p' \
  | sed -r 's/(,|\|)/ /g';
}

parse_value_types_from_usage() {
    cat - \
  | sed -rn 's/^([ ]*)(--?[^ \*]+|,|_)+[ ]*<(.[^>]*).*$/\3/p';
}

parse_args_or_show_help() {
    eval "$(                                                  \
        devcontainer-utils-parse-args                         \
            --names "$(print_usage | parse_names_from_usage)" \
        "$@" <&0                                              \
    | xargs -r -d'\n' -I% echo -n export %\;                  \
    )";
    if test -n "${h:-${help:-${usage:-}}}"; then
        print_usage >&2;
        exit 0;
    fi
}
