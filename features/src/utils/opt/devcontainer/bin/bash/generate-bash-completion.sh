#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-generate-bash-completion [OPTION]...
#
# Generate a bash completion script for a command.
#
# Boolean options:
#  -h,--help,--usage            print this text
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

    set -Eeuo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    local -r command="${c:-${command:?-c|--command is required}}";
    local -r out_dir="$(realpath -m "${o:-${out_dir:-"${HOME}/.bash_completion.d"}}")";
    local -r template="${t:-${template:-${COMPLETION_TMPL:-"$(which devcontainer-utils-bash-completion.tmpl)"}}}";

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

if test -n "${devcontainer_utils_debug:-}" \
&& { test -z "${devcontainer_utils_debug##*"*"*}" \
  || test -z "${devcontainer_utils_debug##*"generate-bash-completion"*}"; }; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

generate_bash_completion "$@";
