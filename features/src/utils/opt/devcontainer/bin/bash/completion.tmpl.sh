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

declare -g -A _devcontainer_utils_completions_usage=();
declare -g -A _devcontainer_utils_completions_script=();
declare -g -A _devcontainer_utils_completions_bool_names=();
declare -g -A _devcontainer_utils_completions_value_names=();
declare -g -A _devcontainer_utils_completions_value_types="";
declare -g -A _devcontainer_utils_completions_option_names="";

_devcontainer_utils_completions() {
    # trap 'sleep 10;' EXIT;

    COMPREPLY=();

    local CMD="$1";

    if test "${_devcontainer_utils_completions_script[${CMD}]:-}" != "$(which "${CMD}")"; then
        _devcontainer_utils_completions_script["${CMD}"]="$(which "${CMD}")";
        if test ${#_devcontainer_utils_completions_script["${CMD}"]} -eq 0; then return; fi
        unset "_devcontainer_utils_completions_usage[${CMD}]";
        unset "_devcontainer_utils_completions_bool_names[${CMD}]";
        unset "_devcontainer_utils_completions_value_names[${CMD}]";
        unset "_devcontainer_utils_completions_value_types[${CMD}]";
        unset "_devcontainer_utils_completions_option_names[${CMD}]";
    fi
    if ! test -v _devcontainer_utils_completions_usage["${CMD}"]; then
        _devcontainer_utils_completions_usage["${CMD}"]="$(${CMD} -h 2>&1)";
        if test ${#_devcontainer_utils_completions_usage[${CMD}]} -eq 0; then return; fi
    fi
    if test "${#_devcontainer_utils_completions_bool_names[${CMD}]}" -eq 0; then
        _devcontainer_utils_completions_bool_names["${CMD}"]="$(_parse_bool_names_from_usage <<< "${_devcontainer_utils_completions_usage[${CMD}]}")";
    fi
    if test "${#_devcontainer_utils_completions_value_names[${CMD}]}" -eq 0; then
        _devcontainer_utils_completions_value_names["${CMD}"]="$(_parse_value_names_from_usage <<< "${_devcontainer_utils_completions_usage[${CMD}]}" | sort -su)";
    fi
    if ! test -v _devcontainer_utils_completions_value_types["${CMD}"]; then
        _devcontainer_utils_completions_value_types["${CMD}"]="$(_zip_names_and_types              \
            <(_parse_value_names_from_usage <<< "${_devcontainer_utils_completions_usage[${CMD}]}") \
            <(_parse_value_types_from_usage <<< "${_devcontainer_utils_completions_usage[${CMD}]}") \
        )";
    fi
    if ! test -v _devcontainer_utils_completions_option_names["${CMD}"]; then
        _devcontainer_utils_completions_option_names["${CMD}"]="${_devcontainer_utils_completions_bool_names[${CMD}]} ${_devcontainer_utils_completions_value_names[${CMD}]}";
    fi

    local cur="${COMP_WORDS[$COMP_CWORD]}";
    local prev="${COMP_WORDS[$COMP_CWORD-1]}";

    if test "${COMP_CWORD}" -gt 1; then
        while read -r name_and_type; do
            local -a pair;
            read -a pair -r <<< "${name_and_type}";
            local name_="${pair[0]}";
            local type_="${pair[*]:1}";
            if [[ ${name_} == "${prev}" ]]; then
                case "${type_}" in
                    "<num>"|"<number>"|"<sec>"|"<retries>")
                        # shellcheck disable=SC2207
                        COMPREPLY=($(grep -P "^[0-9]+$" <<< "${cur}"));
                        return;
                        ;;
                    "<dir>"|"<directory>")
                        _filedir -d;
                        return;
                        ;;
                    "<file>"|"<path>"|"<path/url>")
                        _filedir;
                        return;
                        ;;
                    \(*\))
                        IFS=$'|' read -a list -r <<< "${type_:1:-1}";
                        if test ${#cur} -eq 0; then
                            COMPREPLY=("${list[@]}");
                        else
                            for item in "${list[@]}"; do
                                if [[ "${item}" =~ ^${cur} ]]; then
                                    if [[ "${item}" == *" "* ]]; then
                                        COMPREPLY+=("${item@Q}");
                                    else
                                        COMPREPLY+=("${item}");
                                    fi
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
        done <<< "${_devcontainer_utils_completions_value_types[${CMD}]}";
    fi

    local -a bools="(${_devcontainer_utils_completions_bool_names[${CMD}]})";

    for ((idx_a=0; idx_a < ${#bools[@]}; idx_a+=1)); do
        if [[ ${bools[$idx_a]} == ${cur}* ]]; then
            # shellcheck disable=SC2207
            COMPREPLY=($(compgen -o nosort -W "${_devcontainer_utils_completions_option_names[$CMD]}" -- "${cur}"));
            return;
        fi
    done

    local -a value="(${_devcontainer_utils_completions_value_names[${CMD}]})";

    for ((idx_a=0; idx_a < ${#value[@]}; idx_a+=1)); do
        if [[ ${value[$idx_a]} == ${cur}* ]]; then
            # shellcheck disable=SC2207
            COMPREPLY=($(compgen -o nosort -W "${_devcontainer_utils_completions_option_names[$CMD]}" -- "${cur}"));
            return;
        fi
    done
}

# complete -F _devcontainer_utils_completions ${CMD};
