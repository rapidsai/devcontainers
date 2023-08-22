clone_all() {
    set -euo pipefail;

    for name in $NAMES; do
        clone-$name
    done;
}

if [[ -n "$devcontainer_utils_debug" ]]; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clone_all "$@";
