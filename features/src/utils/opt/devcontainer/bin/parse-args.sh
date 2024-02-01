#! /usr/bin/env bash

# shellcheck disable=SC1091
. "$(dirname "$(realpath -m "${BASH_SOURCE[0]}")")/parse-args-from-docstring.sh";

parse_args() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${devcontainer_utils_debug:-}" \
    && { test -z "${devcontainer_utils_debug##*"*"*}" \
      || test -z "${devcontainer_utils_debug##*"parse-args"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    local -r usage="$(print_usage "${1:-}")";
    shift;

    local idx;
    local key;
    local typ;
    local val;
    local -a arg;

    local -A args=();
    local -a opts=();
    local -A typs=();
    local -a rest=();

    local -A take_map=();
    local -A skip_map=();
    local -A reverse_alias_map=();
    local -Ar alias_map="($(parse_all_names_from_usage     <<< "${usage}" | parse_aliases))";
    local -ar long_bools="($(parse_bool_names_from_usage   <<< "${usage}" | parse_long_names))";
    local -ar long_value="($(parse_value_names_from_usage  <<< "${usage}" | parse_long_names))";
    local -ar short_bools="($(parse_bool_names_from_usage  <<< "${usage}" | parse_short_names))";
    local -ar short_value="($(parse_value_names_from_usage <<< "${usage}" | parse_short_names))";

    for ((idx=0; idx < 2; idx+=1)); do
        if [ "${1:-}" = "--take" ]; then
            shift;
            if test -n "${1:-}"; then
                local -ar take="($(echo "${1}" | parse_args_to_names))";
                for key in "${take[@]}"; do
                    # shellcheck disable=SC2034
                    take_map["${key}"]=1;
                done
                shift;
            fi
        fi
        if [ "${1:-}" = "--skip" ] || [ "${1:-}" = "--passthrough" ]; then
            shift;
            if test -n "${1:-}"; then
                local -ar skip="($(echo "${1}" | parse_args_to_names))";
                for key in "${skip[@]}"; do
                    # shellcheck disable=SC2034
                    skip_map["${key}"]=1;
                done
                shift;
            fi
        fi
    done

    if test ${#take_map[@]} -eq 0; then
        for key in "${long_bools[@]}" "${short_bools[@]}" \
                   "${long_value[@]}" "${short_value[@]}"; do
            take_map[${key}]=1;
        done
    fi

    # Always include the -h,--help flags
    take_map["h"]=1;
    take_map["help"]=1;

    for key in "${!alias_map[@]}"; do
        args["${key}"]="";
        local -a aliases="(${alias_map[${key}]})";
        for alias in "${aliases[@]}"; do
            reverse_alias_map["${alias}"]="${key}";
        done
    done

    for key in "${long_bools[@]}" "${short_bools[@]}"; do typs[${key}]="bool"; done
    for key in "${long_value[@]}" "${short_value[@]}"; do typs[${key}]="value"; done

    local -r optstring="$(                                                                               \
        cat <(parse_bool_names_from_usage  <<< "${usage}" | parse_short_names | xargs -r -I% echo -n %)  \
            <(parse_value_names_from_usage <<< "${usage}" | parse_short_names | xargs -r -I% echo -n %:) \
      | tr -d '[:space:]'                                                                                \
    )";

    if test ${#long_bools[@]} -gt 0 || test ${#long_value[@]} -gt 0; then
        local longoptstring="-:";
    fi

    shopt -s extglob;

    local -r long_bools1="@($(echo -n "${long_bools[@]/%/ |}"   | rev | cut -d'|' -f1 --complement | rev | tr -d '[:space:]'))";
    local -r long_bools2="@($(echo -n "${long_bools[@]/%/ |}"   | rev | cut -d'|' -f1 --complement | rev | tr -d '[:space:]'))=*";
    local -r long_value1="@($(echo -n "${long_value[@]/%/ |}"   | rev | cut -d'|' -f1 --complement | rev | tr -d '[:space:]'))";
    local -r long_value2="@($(echo -n "${long_value[@]/%/ |}"   | rev | cut -d'|' -f1 --complement | rev | tr -d '[:space:]'))=*";
    local -r short_bools1="@($(echo -n "${short_bools[@]/%/ |}" | rev | cut -d'|' -f1 --complement | rev | tr -d '[:space:]'))";
    local -r short_value1="@($(echo -n "${short_value[@]/%/ |}" | rev | cut -d'|' -f1 --complement | rev | tr -d '[:space:]'))";

    while test -n "${1:-}"; do

        # read from stdin on hyphen
        if test "${1:-}" == -; then
            shift;
            set -o noglob;
            # read and split+glob with glob disabled
            eval set "-- $* $(cat)";
            set +o noglob;
            continue;
        fi

        while getopts ":${optstring}${longoptstring:-}" opt; do

            arg=();
            key=;
            val=;
            idx=$((OPTIND-1));

            # shellcheck disable=SC2254
            case "${opt}" in
                # short opt is specified but missing a value
                :)
                    typ="value";
                    key="${OPTARG}";
                    arg+=("-${key}");
                    ;;
                # unknown short opt
                \?)
                    # Compare ${OPTARG} to ${!idx} with its leading `-`.
                    # This only works when getopts is in silent mode, i.e. when `:` is at the front of the optstring.
                    # If getopts is not in silent mode, it does not populate `OPTARG`.
                    if [[ "-${OPTARG}" != "${!idx:-}" ]]; then
                        # Special cases:
                        # -f=foo
                        # -Wno-dev
                        opts+=("${!OPTIND:-}");
                        # Splice the argument at index `OPTIND` out of $@
                        set -- "${@:1:$((OPTIND-1))}" "${@:$((OPTIND+1))}";
                    else
                        # Normal cases:
                        # -f
                        # -f foo
                        opts+=("-${OPTARG}");
                        OPTIND=$((OPTIND <= 1 ? 1 : OPTIND-1));
                        # Splice the argument at index `OPTIND` out of $@
                        set -- "${@:1:$((OPTIND-1))}" "${@:$((OPTIND+1))}";

                        # Peek at the next argument.
                        # If it begins with `-`, leave it for getopts.
                        # Otherwise, push it onto the skipped list and splice it out of $@.
                        if [[ "${!OPTIND:--}" != -* ]]; then
                            opts+=("${!OPTIND}");
                            # Splice the argument at index `OPTIND` out of $@
                            set -- "${@:1:$((OPTIND-1))}" "${@:$((OPTIND+1))}";
                        fi
                    fi
                    break;
                    ;;
                # long opt
                -)
                    case "${OPTARG}" in
                        # known bool opt
                        $long_bools1)
                            typ="bool";
                            val="true";
                            key="${OPTARG}";
                            arg+=("--${key}");
                            ;;
                        # known bool opt with value after =
                        $long_bools2)
                            typ="bool";
                            key="${OPTARG%=*}";
                            val="${OPTARG#*=}";
                            arg+=("--${key}=${val}");
                            ;;
                        # known value opt with value following
                        $long_value1)
                            typ="value";
                            key="${OPTARG}";
                            arg+=("--${key}");
                            if [[ "${!OPTIND:--}" != -* ]]; then
                                val="${!OPTIND}";
                                arg+=("${val}");
                                OPTIND=$((OPTIND + 1));
                            fi
                            ;;
                        # known value opt with value after =
                        $long_value2)
                            typ="value";
                            key="${OPTARG%=*}";
                            val="${OPTARG#*=}";
                            arg+=("--${key}=${val}");
                        ;;
                        # unknown long opt with value after =
                        *=*)
                            opts+=("--${OPTARG}");
                            ;;
                        # unknown long opt with value following
                        *)
                            opts+=("--${OPTARG}");
                            if [[ "${!OPTIND:--}" != -* ]]; then
                                opts+=("${!OPTIND}");
                                OPTIND=$((OPTIND + 1));
                            fi
                            ;;
                    esac
                    ;;
                # known bool opt
                $short_bools1)
                    typ="bool";
                    key="${opt}";
                    val="true";
                    arg+=("-${key}");
                    ;;
                # known value opt with value following
                $short_value1)
                    typ="value";
                    key="${opt}";
                    idx=$((OPTIND-1));
                    case "${OPTARG:-}" in
                        # If OPTARG arg begins with `-`, leave it for getopts.
                        -*)
                            arg+=("-${key}");
                            OPTIND=$((OPTIND - 1));
                            ;;
                        # If the option and value are separated by `=`
                        =*)
                            # strip the `=` and use the right-hand side as the value
                            val="${OPTARG#*=}";
                            if [ -z "${val}" ] && [[ "${!OPTIND}" != -* ]]; then
                                # Handle the case where there's an equals sign and a space between the value, e.g. `-v= foo`
                                val="${!OPTIND}";
                                OPTIND=$((OPTIND + 1));
                            fi
                            arg+=("-${key}=${val}");
                            ;;
                        *)
                            val="${OPTARG:-}";
                            idx=$((OPTIND-1));
                            if test "${!idx:-}" != "${val}"; then
                                arg+=("${!idx:-}");
                            else
                                arg+=("-${key}" "${val}");
                            fi
                            ;;
                    esac
                    ;;
            esac

            if test -n "${key}"; then

                if test -v skip_map["${key}"] || ! test -v take_map["${key}"]; then
                    opts+=("${arg[@]}");
                else
                    if test -v reverse_alias_map["${key}"]; then
                        key="${reverse_alias_map["${key}"]}";
                    fi
                    if test "${typ}" = bool; then
                        args["${key}"]="${val@Q}";
                    elif test -z "${args["${key}"]}"; then
                        args["${key}"]="${val@Q}";
                    else
                        args["${key}"]+=" ${val@Q}";
                    fi
                fi
            fi

            # If the next arg is `--`, break so we handle it below instead of getopts eating it.
            if [[ "${!OPTIND:-}" == -- ]]; then
                rest=("${@:$((OPTIND+1))}");
                OPTIND=1;
                set --;
                break;
            fi
        done # end getopts loop

        shift "$((OPTIND - 1))";

        OPTIND=1;

        while test $# -gt 0; do
            val="${1}";
            if [[ "${val}" == -- ]]; then
                rest=("${@}");
                set --;
            elif [[ "${val}" != -* ]]; then
                rest+=("${val}");
                shift;
            else
                break;
            fi
        done
    done

    if test -n "${args[h]:-}"; then
        cat <<< "${usage}" >&2;
        echo >&2;
        echo "exit 0";
    else
        echo "declare -A ARGS=(";
        for key in "${!args[@]}"; do
            echo "[${key@Q}]=${args["${key}"]@Q}";
        done
        echo ")";
        echo "declare -a OPTS=(${opts[*]@Q})";
        echo "declare -a REST=(${rest[*]@Q})";

        for key in "${!args[@]}"; do
            if test "${typs["${key}"]}" = bool; then
                echo "declare ${key//-/_}=${args["${key}"]}";
            else
                echo "declare -a ${key//-/_}=(${args["${key}"]})";
            fi
            local -a aliases="(${alias_map["${key}"]})";
            for alias in "${aliases[@]}"; do
                echo "declare -n ${alias//-/_}=${key//-/_}";
            done
        done
    fi
}

parse_args "$@" <&0;
