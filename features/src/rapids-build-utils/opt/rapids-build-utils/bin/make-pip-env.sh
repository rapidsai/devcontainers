#!/usr/bin/env bash

# Usage:
#  rapids-make-pip-env [OPTION]...
#
# Make a combined pip virtual environment for all repos.
#
# Boolean options:
#  -h,--help,--usage       print this text
#  -f,--force              Delete the existing pip venv and recreate it from scratch.
#
# Options that require values:
#  -k,--key <key>          Only include the key(s)
#  -m,--manifest <file>    Use a specific manifest.json
#                          (default: ${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"})
#  -o,--omit <repo>        Omit dependencies for repo(s).
#                          (default: none)
#  --repo <repo>           Only include dependencies for repo(s).
#                          (default: all repositories)
#  -r,--requirement <file> Path(s) to additional requirement files to include.

. devcontainer-utils-parse-args-from-docstring;

make_pip_env() {
    set -Eeuo pipefail;

    local env_name="${1}"; shift;
    local env_file_name="${env_name}.requirements.txt";

    parse_args_or_show_help - <<< "$@";

    # Remove the current virtual env if called with `-f|--force`
    if test -n "${f:-${force:-}}"; then
        rm -rf "$HOME/.local/share/venvs/${env_name}" \
               "$HOME/.local/share/venvs/${env_file_name}";
    fi

    local new_env_path="$(realpath -m /tmp/${env_file_name})";
    local old_env_path="$(realpath -m ~/.local/share/venvs/${env_file_name})";

    rapids-make-pip-dependencies "$@"     \
  | (grep -v -E '^$' || [ "$?" == "1" ])  \
  | tr -s "[:blank:]"                     \
  | LC_ALL=C sort -u                      \
  > "${new_env_path}"

    if test -f "${new_env_path}"; then

        # If the venv doesn't exist, make one
        if [ ! -d ~/.local/share/venvs/${env_name} ]; then
            echo -e "Creating '${env_name}' virtual environment\n" 1>&2;
            echo -e "Requirements (${env_file_name}):\n" 1>&2;
            cat "${new_env_path}";
            echo "";

            python -m venv --system-site-packages ~/.local/share/venvs/${env_name};
            . ~/.local/share/venvs/${env_name}/bin/activate;
            python -m pip install -U pip;
            python -m pip install --pre -I -r "${new_env_path}";
        # If the venv does exist but it's different from the generated one,
        # print the diff between the envs and update it
        elif ! diff -BNqw "${old_env_path}" "${new_env_path}" >/dev/null 2>&1; then
            echo -e "Updating '${env_name}' virtual environment\n" 1>&2;
            echo -e "Requirements (${env_file_name}):\n" 1>&2;

            # Print the diff to the console for debugging
            [ ! -f "${old_env_path}" ]                         \
             && cat "${new_env_path}"                          \
             || diff -BNyw "${old_env_path}" "${new_env_path}" \
             || true                                           \
             && echo "";

            # Update the current venv
            . ~/.local/share/venvs/${env_name}/bin/activate;
            python -m pip install -U pip;
            python -m pip install --pre -U -r "${new_env_path}";
        fi

        cp -a "${new_env_path}" "${old_env_path}";
    fi
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"make-pip-env"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

make_pip_env "${DEFAULT_VIRTUAL_ENV:-rapids}" "$@";

if test -f ~/.local/share/venvs/${DEFAULT_VIRTUAL_ENV:-rapids}/bin/activate; then
    . ~/.local/share/venvs/${DEFAULT_VIRTUAL_ENV:-rapids}/bin/activate;
fi
