#!/usr/bin/env bash

. devcontainer-utils-parse-args-from-docstring;

_zip_lines() {
    local line_1="";
    local args_1=();
    local line_2="";
    while read -r line_1; do
        args_1=(${line_1});
        while read -r line_2; do
            local idx;
            for ((idx=0; idx < ${#args_1[@]}; idx+=1)); do
                echo "${line_2}";
            done
            break;
        done < "${2}";
    done < "${1}";
}

${NAME}_script="";
${NAME}_usage="";
${NAME}_bool_names=();
${NAME}_value_names=();
${NAME}_value_types="";
${NAME}_option_names="";

_${NAME}_completions() {
    # trap 'sleep 10;' EXIT;

    COMPREPLY=();

    if test -z "${${NAME}_script}"; then
        ${NAME}_script="$(which ${CMD})";
        if test -z "${${NAME}_script}"; then return; fi
    fi
    if test -z "${${NAME}_usage}"; then
        ${NAME}_usage="$(sed -n '2,/^$/p' "${${NAME}_script}" | sed -r 's/^# ?//')";
        if test -z "${${NAME}_usage}"; then return; fi
    fi
    if test "${#${NAME}_bool_names[@]}" -eq 0; then
        ${NAME}_bool_names=($(parse_bool_names_from_usage <<< "${${NAME}_usage}"));
    fi
    if test "${#${NAME}_value_names[@]}" -eq 0; then
        ${NAME}_value_names=($(parse_value_names_from_usage <<< "${${NAME}_usage}"));
    fi
    if test -z "${${NAME}_value_types}"; then
        ${NAME}_value_types="$(_zip_lines                          \
            <(parse_value_names_from_usage <<< "${${NAME}_usage}") \
            <(parse_value_types_from_usage <<< "${${NAME}_usage}") \
        )";
    fi
    if test -z "${${NAME}_option_names}"; then
        ${NAME}_option_names="${${NAME}_bool_names[*]} ${${NAME}_value_names[*]}";
    fi

    local type_;
    local idx_a=0;
    local idx_b=0;

    if test "${COMP_CWORD}" -gt 1; then
        for ((idx_a=0; idx_a < ${#${NAME}_value_names[@]}; idx_a+=1)); do
            if [[ ${${NAME}_value_names[$idx_a]} == ${COMP_WORDS[$COMP_CWORD-1]}* ]]; then
                while read -r type_; do
                    if test ${idx_b} != ${idx_a}; then
                        idx_b=$((idx_b + 1));
                        continue;
                    fi
                    case "${type_}" in
                        num)
                            COMPREPLY=($(grep -P "^[0-9]+$" <<< "${COMP_WORDS[$COMP_CWORD]}"));
                            ;;
                        dir)
                            COMPREPLY=($(compgen -o nosort -o dirnames -- "${COMP_WORDS[$COMP_CWORD]}"));
                            ;;
                        file)
                            COMPREPLY=($(compgen -o nosort -o filenames -- "${COMP_WORDS[$COMP_CWORD]}"));
                            ;;
                        path)
                            COMPREPLY=($(compgen -o nosort -o default -- "${COMP_WORDS[$COMP_CWORD]}"));
                            ;;
                        *)
                            COMPREPLY=();
                            ;;
                    esac
                    break;
                done <<< "${${NAME}_value_types}";
                return;
            fi
        done
    fi

    for ((idx_a=0; idx_a < ${#${NAME}_bool_names[@]}; idx_a+=1)); do
        if [[ ${${NAME}_bool_names[$idx_a]} == ${COMP_WORDS[$COMP_CWORD]}* ]]; then
            COMPREPLY=($(compgen -o nosort -W "${${NAME}_option_names}" -- "${COMP_WORDS[$COMP_CWORD]}"));
            return;
        fi
    done

    for ((idx_a=0; idx_a < ${#${NAME}_value_names[@]}; idx_a+=1)); do
        if [[ ${${NAME}_value_names[$idx_a]} == ${COMP_WORDS[$COMP_CWORD]}* ]]; then
            COMPREPLY=($(compgen -o nosort -W "${${NAME}_option_names}" -- "${COMP_WORDS[$COMP_CWORD]}"));
            return;
        fi
    done
}

complete -F _${NAME}_completions ${CMD};
