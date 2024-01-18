#! /usr/bin/env bash

parse_args() {
    set -euo pipefail;

    local keys=();
    local rest=();
    declare -A dict;

    local vars="(.*)";
    local vars_array=();
    if [ "${1:-}" = "--names" ]; then
        shift;
        vars="$(tr -d '[:space:]' <<< "${1}"  | rev | cut -d'|' -f1 --complement | rev)";
        vars_array=("${vars//|/ }");
        readarray -t vars_array < <(
            for str in "${vars_array[@]}"; do
                printf '%d\t%s\n' "${#str}" "$str"
            done | sort -k 1,1nr -k 2 | cut -f 2-
        );
        vars="(${vars})";
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
            eval set "-- $@ $(cat - | tr -s '[:space:]' | xargs -d'\n' -r echo -n)";
            continue;
        # --
        elif grep -qP '^--$' <<< "${arg:-}"; then
            shift;
            rest+=("${@@Q}");
            break;
        # -foo=bar | --foo=bar
        elif grep -qP '^--?[^\s]+=.*$' <<< "${arg:-}"; then
            shift;
            key="${arg#-}";
            key="${key#-}";
            key="${key%=*}";
            val="${arg#*=}";
        # -foo bar | --foo bar
        elif grep -qP '^--?[^\s]+$' <<< "${arg:-}"; then
            shift;
            # -fooval
            local found="";
            if test "${#vars_array[@]}" -gt 0 \
            && grep -qP "^--?${vars}([^\s])+$" <<< "${arg:-}"; then
                for name in ${vars_array[@]}; do
                    if grep -qP "^--?${name}([0-9]|\.)+$" <<< "${arg:-}"; then
                        key="${name}";
                        val="${arg#-}";
                        val="${val#-}";
                        val="${val#"${name}"}";
                        found="1";
                        break;
                    fi
                done
            fi
            if test -z "${found}"; then
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
            fi
        else
            rest+=("${@@Q}");
            break;
        fi

        if grep -qP "^${vars}$" <<< "${key}"; then
            key="${key//-/_}";
            keys+=("$key");
            if test -v dict[$key]; then
                dict[$key]+=" ${val@Q}";
                if ! test -v __${key}_ary; then
                    declare __${key}_ary;
                    eval __${key}_ary="";
                fi
            else
                dict[$key]="${val@Q}";
            fi
        else
            rest+=("${arg}");
        fi
    done

    keys+=("__rest__");
    dict["__rest__"]="(${rest[@]})";

    keys=($(echo "${keys[@]}" | xargs -r -d' ' -n1 echo -e | sort -su));

    { set +x; } 2>/dev/null;

    local keyi=0;

    for ((keyi=0; keyi < ${#keys[@]}; keyi+=1)); do
        key=${keys[$keyi]};
        val=${dict[$key]};
        if ! test -v __${key}_ary; then
            echo "${key}=${val}";
        else
            echo "${key}=(${val})";
        fi
    done
}

if test -n "${devcontainer_utils_debug:-}" \
&& ( test -z "${devcontainer_utils_debug##*"all"*}" \
  || test -z "${devcontainer_utils_debug##*"parse-args"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(parse_args "$@");
