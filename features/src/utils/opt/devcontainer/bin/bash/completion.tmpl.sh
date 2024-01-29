#!/usr/bin/env bash

# shellcheck disable=SC1091
. devcontainer-utils-parse-args-from-docstring;

_zip_names_and_types() {
    local line_1="";
    local args_1=();
    local line_2="";
    while read -r line_1; do
        read -ra args_1 <<< "${line_1}";
        while read -r line_2; do
            local idx;
            for ((idx=0; idx < ${#args_1[@]}; idx+=1)); do
                echo "${args_1[${idx}]} ${line_2}";
            done
            break;
        done < "${2}";
    done < "${1}";
}

declare -A usage=();
declare -A script=();
declare -A bool_names=();
declare -A value_names=();
declare -A value_types="";
declare -A option_names="";

_devcontainer_utils_completions() {
    # trap 'sleep 10;' EXIT;

    COMPREPLY=();

    local CMD="$1";

    if test "${script[${CMD}]:-}" != "$(which "${CMD}")"; then
        script["${CMD}"]="$(which "${CMD}")";
        if test ${#script["${CMD}"]} -eq 0; then return; fi
        unset "usage[${CMD}]";
        unset "bool_names[${CMD}]";
        unset "value_names[${CMD}]";
        unset "value_types[${CMD}]";
        unset "option_names[${CMD}]";
    fi
    if ! test -v usage["${CMD}"]; then
        usage["${CMD}"]="$(sed -n '2,/^$/p' "${script[${CMD}]}" | sed -r 's/^# ?//')";
        if test ${#usage[${CMD}]} -eq 0; then return; fi
    fi
    if test "${#bool_names[${CMD}]}" -eq 0; then
        bool_names["${CMD}"]="$(parse_bool_names_from_usage <<< "${usage[${CMD}]}")";
    fi
    if test "${#value_names[${CMD}]}" -eq 0; then
        value_names["${CMD}"]="$(parse_value_names_from_usage <<< "${usage[${CMD}]}")";
    fi
    if ! test -v value_types["${CMD}"]; then
        value_types["${CMD}"]="$(_zip_names_and_types              \
            <(parse_value_names_from_usage <<< "${usage[${CMD}]}") \
            <(parse_value_types_from_usage <<< "${usage[${CMD}]}") \
        )";
    fi
    if ! test -v option_names["${CMD}"]; then
        option_names["${CMD}"]="${bool_names[${CMD}]} ${value_names[${CMD}]}";
    fi

    if test "${COMP_CWORD}" -gt 1; then
        while read -r name_and_type; do
            local -a pair;
            read -a pair -r <<< "${name_and_type}";
            local name_="${pair[0]}";
            local type_="${pair[1]}";
            if [[ ${name_} == ${COMP_WORDS[$COMP_CWORD-1]}* ]]; then
                case "${type_}" in
                    "<num>")
                        # shellcheck disable=SC2207
                        COMPREPLY=($(grep -P "^[0-9]+$" <<< "${COMP_WORDS[$COMP_CWORD]}"));
                        return;
                        ;;
                    "<dir>")
                        # shellcheck disable=SC2207
                        COMPREPLY=($(compgen -o nosort -o dirnames -- "${COMP_WORDS[$COMP_CWORD]}"));
                        return;
                        ;;
                    "<file>")
                        # shellcheck disable=SC2207
                        COMPREPLY=($(compgen -o nosort -o filenames -- "${COMP_WORDS[$COMP_CWORD]}"));
                        return;
                        ;;
                    "<path>")
                        # shellcheck disable=SC2207
                        COMPREPLY=($(compgen -o nosort -o default -- "${COMP_WORDS[$COMP_CWORD]}"));
                        return;
                        ;;
                    \(*\))
                        local -a list=();
                        IFS=$'|' read -a list -r <<< "${type_:1:-1}";
                        if test ${#COMP_WORDS[$COMP_CWORD]} -eq 0; then
                            COMPREPLY=("${list[@]}");
                        else
                            for item in "${list[@]}"; do
                                if [[ ${item} =~ ^${COMP_WORDS[$COMP_CWORD]} ]]; then
                                    COMPREPLY+=("${item}");
                                fi
                            done
                        fi
                        return;
                        ;;
                    *)
                        COMPREPLY=();
                        return;
                        ;;
                esac
            fi
        done <<< "${value_types[${CMD}]}";
    fi

    declare -a bools="(${bool_names[${CMD}]})";

    for ((idx_a=0; idx_a < ${#bools[@]}; idx_a+=1)); do
        if [[ ${bools[$idx_a]} == ${COMP_WORDS[$COMP_CWORD]}* ]]; then
            # shellcheck disable=SC2207
            COMPREPLY=($(compgen -o nosort -W "${option_names[$CMD]}" -- "${COMP_WORDS[$COMP_CWORD]}"));
            return;
        fi
    done

    declare -a value="(${value_names[${CMD}]})";

    for ((idx_a=0; idx_a < ${#value[@]}; idx_a+=1)); do
        if [[ ${value[$idx_a]} == ${COMP_WORDS[$COMP_CWORD]}* ]]; then
            # shellcheck disable=SC2207
            COMPREPLY=($(compgen -o nosort -W "${option_names[$CMD]}" -- "${COMP_WORDS[$COMP_CWORD]}"));
            return;
        fi
    done
}

# complete -F _devcontainer_utils_completions ${CMD};
