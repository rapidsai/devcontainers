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

. devcontainer-utils-parse-args-from-docstring;

generate_bash_completion() {

    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    local command="${c:-${command:?-c|--command is required}}";
    local out_dir="$(realpath -m "${o:-${out_dir:-"${HOME}/.bash_completion.d"}}")";
    local template="${t:-${template:-${COMPLETION_TMPL:-"$(which devcontainer-utils-bash-completion.tmpl)"}}}";

    if test -f "${template}"; then
        mkdir -p "${out_dir}";
        cat "${template}"                     \
      | CMD="${command}"                      \
        NAME="${command//-/_}"                \
        envsubst '$CMD $NAME'                 \
      | tee "${out_dir}/${command}" >/dev/null;
    fi
}

if test -n "${devcontainer_utils_debug:-}" \
&& ( test -z "${devcontainer_utils_debug##*"all"*}" \
  || test -z "${devcontainer_utils_debug##*"generate-bash-completion"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

generate_bash_completion "$@";
