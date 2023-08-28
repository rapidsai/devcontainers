${SCRIPT}_all() {
    set -euo pipefail;

    for name in ${NAMES}; do
        if type ${SCRIPT}-${name} >/dev/null 2>&1; then
            ${SCRIPT}-${name} "$@";
        fi
    done
}

if [[ -n "${rapids_build_utils_debug:-}" ]]; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

${SCRIPT}_all "$@";
