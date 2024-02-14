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
#  -c,--command  <name>         Name of the command for which to generate the bash completion.
#  -o,--out-dir  <path>         Path to the completion script output directory
#                               (default: ${HOME}/.bash_completion.d)
#  -t,--template <path>         Path to the bash completion script template file
#                               (default: `which devcontainer-utils-bash-completion.tmpl`)

generate_bash_completion() {
    local -;
    set -euo pipefail;

    local -r utils="$(dirname "$(realpath -m "${BASH_SOURCE[0]}")")/..";

    eval "$("${utils}/parse-args.sh" "$0" "$@" <&0)";

    # shellcheck disable=SC1091
    . "${utils}/debug-output.sh" 'devcontainer_utils_debug' 'generate-bash-completion';

    command="${c:?-c|--command is required}";
    out_dir="$(realpath -m "${o:-"${HOME}/.bash_completion.d"}")";
    template="${t:-${COMPLETION_TMPL:-"$(which devcontainer-utils-bash-completion.tmpl)"}}";

    if test -f "${template}"; then
        mkdir -p "${out_dir}";
        local file="${out_dir}/devcontainer-utils-completions";
        if ! test -f "${file}"; then
            cp "${template}" "${file}";
        fi

        local str="complete -F _devcontainer_utils_completions ${command};";
        if ! grep -q "${str}" "${file}"; then
            echo "${str}" >> "${file}";
        fi
    fi
}

generate_bash_completion "$@";
