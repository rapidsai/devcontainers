#! /usr/bin/env bash

# shellcheck disable=SC1091
. "$(dirname "$(realpath -m "${BASH_SOURCE[0]}")")/parse-args-from-docstring.sh";

_parse_args_for_file() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC1091
    . "$(dirname "$(realpath -m "${BASH_SOURCE[0]}")")/debug-output.sh" \
        'devcontainer_utils_debug' 'parse-args';

    local -r usage="$(_print_usage "${1:-}")";
    shift;

    local idx;
    local key;
    local val;
    local -a arg;

    local -A take_map=();
    local -A skip_map=();

    for ((idx=0; idx < 2; idx+=1)); do
        if [ "${1:-}" = "--take" ]; then
            shift;
            if test -n "${1:+x}"; then
                local -ar take="($(_parse_args_to_names <<< "${1}" | tr '\n' ' ' | tr -s '[:blank:]'))";
                for key in "${take[@]}"; do
                    # shellcheck disable=SC2034
                    take_map["${key}"]=1;
                done
                shift;
            fi
        fi
        if [ "${1:-}" = "--skip" ]; then
            shift;
            if test -n "${1:+x}"; then
                local -ar skip="($(_parse_args_to_names <<< "${1}" | tr '\n' ' ' | tr -s '[:blank:]'))";
                for key in "${skip[@]}"; do
                    # shellcheck disable=SC2034
                    skip_map["${key}"]=1;
                done
                shift;
            fi
        fi
    done

    # Quick early exit for `-h,--help`
    if [[ " $* " == *" -h "* ]] || [[ " $* " == *" --help "* ]]; then
        cat <<< "${usage}" >&2;
        echo >&2;
        echo "exit 0";
        return;
    fi

    local -A _map=();
    local -a args=();
    local -a opts=();
    local -a rest=();

    local -A reverse_alias_map=();
    local -Ar alias_map="($(_parse_all_names_from_usage     <<< "${usage}" | _parse_aliases))";
    local -ar long_bools="($(_parse_bool_names_from_usage   <<< "${usage}" | _parse_long_names))";
    local -ar long_value="($(_parse_value_names_from_usage  <<< "${usage}" | _parse_long_names))";
    local -ar short_bools="($(_parse_bool_names_from_usage  <<< "${usage}" | _parse_short_names))";
    local -ar short_value="($(_parse_value_names_from_usage <<< "${usage}" | _parse_short_names))";

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
        _map["${key}"]="";
        local -a aliases="(${alias_map[${key}]})";
        for alias in "${aliases[@]}"; do
            reverse_alias_map["${alias}"]="${key}";
        done
    done


    local -r optstring="$(                                                                                 \
        cat <(_parse_bool_names_from_usage  <<< "${usage}" | _parse_short_names | xargs -r -I% echo -n %)  \
            <(_parse_value_names_from_usage <<< "${usage}" | _parse_short_names | xargs -r -I% echo -n %:) \
      | tr -d '[:space:]'                                                                                  \
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

    local __xtrace=;

    _disable_xtrace() {
        if test -o xtrace; then
            __xtrace=1;
            set +x;
        fi
    }

    _enable_xtrace() {
        if test -n "${__xtrace:+x}"; then
            __xtrace=0;
            set -x;
        fi
    }

    while test -n "${1:+x}"; do

        # If the first arg is `-`, read from stdin on hyphen
        if test "${1:+${1:0:3}}" == -; then
            shift;
            set -o noglob;
            { _disable_xtrace; } 2>/dev/null;
            # read and split+glob with glob disabled
            eval set "-- $* $(cat)";
            { _enable_xtrace; } 2>/dev/null
            set +o noglob;
            continue;
        fi

        # If the first arg is `--`, break.
        if [[ "${1:+${1:0:3}}" == -- ]]; then
            { _disable_xtrace; } 2>/dev/null;
            rest=("${@}");
            { _enable_xtrace; } 2>/dev/null
            set --;
            break;
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
                    key="${OPTARG}";
                    arg+=("-${key}");
                    ;;
                # unknown short opt
                \?)
                    if test "${OPTARG}" == "h"; then
                        key="${OPTARG}";
                        val="-${key}";
                        arg+=("-${key}");
                    # Compare ${OPTARG} to ${!idx} with its leading `-`.
                    # This only works when getopts is in silent mode, i.e. when `:` is at the front of the optstring.
                    # If getopts is not in silent mode, it does not populate `OPTARG`.
                    elif [[ "-${OPTARG}" != "${!idx:-}" ]]; then
                        { _disable_xtrace; } 2>/dev/null;
                        # Special cases:
                        # -f=foo
                        # -Wno-dev
                        opts+=("${!OPTIND:-}");
                        # Splice the argument at index `OPTIND` out of $@
                        set -- "${@:1:$((OPTIND-1))}" "${@:$((OPTIND+1))}";
                        { _enable_xtrace; } 2>/dev/null
                        break;
                    else
                        # Normal cases:
                        # -f
                        # -f foo
                        opts+=("-${OPTARG}");
                        OPTIND=$((OPTIND <= 1 ? 1 : OPTIND-1));
                        { _disable_xtrace; } 2>/dev/null;
                        # Splice the argument at index `OPTIND` out of $@
                        set -- "${@:1:$((OPTIND-1))}" "${@:$((OPTIND+1))}";
                        { _enable_xtrace; } 2>/dev/null

                        # Peek at the next argument.
                        # If it begins with `-`, leave it for getopts.
                        # Otherwise, push it onto the skipped list and splice it out of $@.
                        if [[ ${OPTIND} -le ${#@} && "${!OPTIND:+${!OPTIND:0:1}}" != - ]]; then
                            { _disable_xtrace; } 2>/dev/null;
                            opts+=("${!OPTIND}");
                            # Splice the argument at index `OPTIND` out of $@
                            set -- "${@:1:$((OPTIND-1))}" "${@:$((OPTIND+1))}";
                            { _enable_xtrace; } 2>/dev/null
                        fi
                        break;
                    fi
                    ;;
                # long opt
                -)
                    case "${OPTARG}" in
                        # known bool opt
                        $long_bools1)
                            key="${OPTARG}";
                            val="--${key}";
                            arg+=("--${key}");
                            ;;
                        # known bool opt with value after =
                        $long_bools2)
                            key="${OPTARG%=*}";
                            val="--${OPTARG}";
                            arg+=("--${OPTARG}");
                            ;;
                        # known value opt with value following
                        $long_value1)
                            key="${OPTARG}";
                            arg+=("--${key}");
                            if [[ ${OPTIND} -le ${#@} && "${!OPTIND:+${!OPTIND:0:1}}" != - ]]; then
                                { _disable_xtrace; } 2>/dev/null;
                                val="${!OPTIND}";
                                arg+=("${val}");
                                { _enable_xtrace; } 2>/dev/null
                                OPTIND=$((OPTIND + 1));
                            fi
                            ;;
                        # known value opt with value after =
                        $long_value2)
                            key="${OPTARG%=*}";
                            { _disable_xtrace; } 2>/dev/null;
                            val="${OPTARG#*=}";
                            arg+=("--${key}=${val}");
                            { _enable_xtrace; } 2>/dev/null
                        ;;
                        # unknown long opt with value after =
                        *=*)
                            opts+=("--${OPTARG}");
                            ;;
                        # unknown long opt with value following
                        *)
                            if test "${OPTARG}" == "help"; then
                                key="${OPTARG}";
                                val="--${key}";
                                arg+=("--${key}");
                            else
                                opts+=("--${OPTARG}");
                                if [[ ${OPTIND} -le ${#@} && "${!OPTIND:+${!OPTIND:0:1}}" != - ]]; then
                                    { _disable_xtrace; } 2>/dev/null;
                                    opts+=("${!OPTIND}");
                                    { _enable_xtrace; } 2>/dev/null
                                    OPTIND=$((OPTIND + 1));
                                fi
                            fi
                            ;;
                    esac
                    ;;
                # known bool opt
                $short_bools1)
                    key="${opt}";
                    val="-${key}";
                    arg+=("-${key}");
                    ;;
                # known value opt with value following
                $short_value1)
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
                            { _disable_xtrace; } 2>/dev/null;
                            val="${OPTARG#*=}";
                            { _enable_xtrace; } 2>/dev/null
                            if [ -z "${val}" ] && [[ "${!OPTIND:+${!OPTIND:0:1}}" != - ]]; then
                                # Handle the case where there's an equals sign and a space between the value, e.g. `-v= foo`
                                { _disable_xtrace; } 2>/dev/null;
                                val="${!OPTIND}";
                                { _enable_xtrace; } 2>/dev/null
                                OPTIND=$((OPTIND + 1));
                            fi
                            { _disable_xtrace; } 2>/dev/null;
                            arg+=("-${key}=${val}");
                            { _enable_xtrace; } 2>/dev/null
                            ;;
                        *)
                            { _disable_xtrace; } 2>/dev/null;
                            val="${OPTARG:-}";
                            idx=$((OPTIND-1));
                            if test "${!idx:-}" != "${val}"; then
                                arg+=("${!idx:-}");
                            else
                                arg+=("-${key}" "${val}");
                            fi
                            { _enable_xtrace; } 2>/dev/null
                            ;;
                    esac
                    ;;
            esac

            if test -n "${key:+x}"; then

                if test -v skip_map["${key}"] || ! test -v take_map["${key}"]; then
                    opts+=("${arg[@]}");
                else
                    args+=("${arg[@]}");
                    if test -v reverse_alias_map["${key}"]; then
                        key="${reverse_alias_map["${key}"]}";
                    fi
                    if ! test -n "${_map["${key}"]:+x}"; then
                        { _disable_xtrace; } 2>/dev/null;
                        _map["${key}"]="${val@Q}";
                        { _enable_xtrace; } 2>/dev/null
                    else
                        { _disable_xtrace; } 2>/dev/null;
                        _map["${key}"]+=" ${val@Q}";
                        { _enable_xtrace; } 2>/dev/null
                    fi
                fi
            fi

            # If the next arg is `--`, break so we handle it below instead of getopts eating it.
            if [[ "${!OPTIND:+${!OPTIND:0:3}}" == -- ]]; then
                break;
            fi
        done # end getopts loop

        shift "$((OPTIND - 1))";

        OPTIND=1;

        while test $# -gt 0; do
            { _disable_xtrace; } 2>/dev/null;
            val="${1}";
            { _enable_xtrace; } 2>/dev/null
            if [[ "${val:+${val:0:3}}" == -- ]]; then
                { _disable_xtrace; } 2>/dev/null;
                rest=("${@}");
                { _enable_xtrace; } 2>/dev/null
                set --;
            elif [[ "${val:+${val:0:1}}" != - ]]; then
                { _disable_xtrace; } 2>/dev/null;
                rest=("${@}");
                { _enable_xtrace; } 2>/dev/null
                set --;
            else
                break;
            fi
        done
    done

    if test -n "${_map[h]:+x}"; then
        cat <<< "${usage}" >&2;
        echo >&2;
        echo "exit 0";
    else
        { _disable_xtrace; } 2>/dev/null;
        echo "declare -A ARGS_MAP=(";
        for key in "${!_map[@]}"; do
            echo "[${key@Q}]=${_map["${key}"]@Q}";
        done
        echo ")";
        echo "declare -a ARGS=(${args[*]@Q})";
        echo "declare -a OPTS=(${opts[*]@Q})";
        echo "declare -a REST=(${rest[*]@Q})";

        for key in "${!_map[@]}"; do
            local k_="${key}";
            k_="${k_//-/_}";
            k_="${k_//./_}";
            echo "declare -a ${k_}=(${_map["${key}"]})";
            local -a aliases="(${alias_map["${key}"]})";
            for alias in "${aliases[@]}"; do
                local a_="${alias}";
                a_="${a_//-/_}";
                a_="${a_//./_}";
                echo "declare -n ${a_}=${k_}";
            done
        done
        { _enable_xtrace; } 2>/dev/null
    fi
}

if [ "$(basename "${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}")" = parse-args.sh ] \
|| [ "$(basename "${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}")" = devcontainer-utils-parse-args ]; then
    _parse_args_for_file "$@" <&0;
fi
