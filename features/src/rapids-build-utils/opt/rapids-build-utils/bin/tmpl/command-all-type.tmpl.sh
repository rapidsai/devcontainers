${COMMAND}_all_${TYPE}() {
    set -euo pipefail;
    local exe
    for name in ${NAMES}; do
        exe="${COMMAND}-${name}-${TYPE}"
        if type $exe >/dev/null 2>&1; then $exe "$@"; fi
    done
}

if [[ -n "${rapids_build_utils_debug:-}" ]]; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

${COMMAND}_all_${TYPE} "$@";
