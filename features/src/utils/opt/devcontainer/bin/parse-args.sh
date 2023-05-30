#! /usr/bin/env bash

clone_git_repo() {
    set -euo pipefail;

    # PS4='+ ${LINENO}: '; set -x;

    local keys=();
    local rest=();
    declare -A dict;

    local vars="^(.*)$";
    if [ "${1:-}" = "--names" ]; then
        shift;
        vars="^(${1})$";
        shift;
    fi

    while test -n "${1:-}"; do
        local arg="${1:-}";
        local key=;
        local val=;

        if false; then
            continue;
        # --
        elif echo "${arg:-}" | grep -qP '^--$'; then
            shift;
            rest+=("${@}");
            break;
        # -foo=bar | --foo=bar
        elif echo "${arg:-}" | grep -qP '^--?[^\s]+=.*$'; then
            shift;
            key="${arg#-}";
            key="${key#-}";
            key="${key%=*}";
            val="${arg#*=}";
        # -foo bar | --foo bar
        elif echo "${arg:-}" | grep -qP '^--?[\w]+$'; then
            shift;
            key="${arg#-}";
            key="${key#-}";
            if [ -n "${1:-}" ]; then
                if echo "${1}" | grep -qP '^-.*$'; then
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

    keys="$(echo "${keys[@]}" | xargs -r -d' ' -n1 echo -e | sort -d | uniq)";

    # { set +x; } 2>/dev/null;

    for key in ${keys}; do
        echo "${key}=${dict[$key]}";
    done
}

clone_git_repo "$@";
