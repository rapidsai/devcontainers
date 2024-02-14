#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-generate-bash-completion [OPTION]...
#
# Generate a bash completion script for a command.
#
# Boolean options:
#  -h,--help                    print this text
#  -v,--verbose                 verbose output
#
# Options that require values:
#  -c,--command  <name>         Command name(s) for which to generate bash completions.
#  -o,--out-file <file>         Path to write the completion script file
#                               (default: ${HOME}/.bash_completion.d/devcontainer-utils-completions)
#  -t,--template <file>         Path to the bash completion script template file
#                               (default: `which devcontainer-utils-bash-completion.tmpl`)

generate_bash_completion() {
    local -;
    set -euo pipefail;

    local -r utils="$(dirname "$(realpath -m "${BASH_SOURCE[0]}")")/..";

    eval "$("${utils}/parse-args.sh" "$0" "$@" <&0)";

    # shellcheck disable=SC1091
    . "${utils}/debug-output.sh" 'devcontainer_utils_debug' 'generate-bash-completion';

    : "${command:?-c|--command is required}";
    out_file="$(realpath -m "${o:-"${HOME}/.bash_completion.d/devcontainer-utils-completions"}")";
    template="${t:-${COMPLETION_TMPL:-"$(which devcontainer-utils-bash-completion.tmpl)"}}";

    if test -f "${template}"; then
        mkdir -p "$(dirname "${out_file}")";
        cp -n "${template}" "${out_file}";
        local cmd;
        for cmd in "${command[@]}"; do
            local str="complete -F _devcontainer_utils_completions ${cmd};";
            if ! grep -q "${str}" "${out_file}"; then
                echo "${str}" >> "${out_file}";
            fi
        done
    fi
}

generate_bash_completion "$@" <&0;
