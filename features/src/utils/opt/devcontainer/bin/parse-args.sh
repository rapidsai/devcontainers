#! /usr/bin/env bash

parse_args() {
    set -euo pipefail;

    local keys=();
    local rest=();
    declare -A dict;

    local vars="^(.*)$";
    if [ "${1:-}" = "--names" ]; then
        shift;
        vars="^($(tr -d '[:space:]' <<< "${1}"))$";
        shift;
    fi

    while test -n "${1:-}"; do
        local arg="${1:-}";
        local key=;
        local val=;

        if false; then
            continue;
        # read args from stdin
        elif grep -qP '^-$' <<< "${arg:-}"; then
            shift;
            set -- ${@} $(cat - | xargs -r echo);
            continue;
        # --
        elif grep -qP '^--$' <<< "${arg:-}"; then
            shift;
            rest+=("${@}");
            break;
        # -foo=bar | --foo=bar
        elif grep -qP '^--?[^\s]+=.*$' <<< "${arg:-}"; then
            shift;
            key="${arg#-}";
            key="${key#-}";
            key="${key%=*}";
            val="${arg#*=}";
        # -foo bar | --foo bar
        elif grep -qP '^--?[\w]+$' <<< "${arg:-}"; then
            shift;
            key="${arg#-}";
            key="${key#-}";
            if ! grep -qE "^$" <<< "${1:-}"; then
                if grep -qP '^-.*$' <<< "${1}"; then
                    val="true";
                else
                    val="${1}";
                    arg+=" ${val}";
                    shift;
                fi
            else
                val="true";
            fi
        else
            rest+=("${@}");
            break;
        fi

        if echo "${key}" | grep -qP "${vars}"; then
            keys+=("${key}");
            dict[$key]="$(printf %q "${val}")";
        else
            rest+=("${arg}");
        fi
    done

    keys+=("__rest__");
    dict["__rest__"]="(${rest[@]})";

    keys=($(echo "${keys[@]}" | xargs -r -d' ' -n1 echo -e | sort -s | uniq));

    { set +x; } 2>/dev/null;

    local keyi=1;

    for ((keyi=1; keyi < ${#keys[@]}; keyi+=1)); do
        echo "${keys[$keyi]}=${dict[${keys[$keyi]}]}";
    done

    echo "${keys[0]}=${dict[${keys[0]}]}";
}

# if test -n "${devcontainer_utils_debug:-}"; then
#     PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
# fi

(parse_args "$@");
