#! /usr/bin/env bash

make_pip_env() {

    set -euo pipefail;

    local force=;
    local env_name="${1}";
    local env_file_name="${env_name}.requirements.txt";

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            f|force                           |
        ' - <<< "${@:2}"                      \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    # Remove the current virtual env if called with `-f|--force`
    if test -n "${f:-${force:-}}"; then
        rm -rf "$HOME/.local/share/venvs/${env_name}" \
               "$HOME/.local/share/venvs/${env_file_name}";
    fi

    local new_env_path="$(realpath -m /tmp/${env_file_name})";
    local old_env_path="$(realpath -m ~/.local/share/venvs/${env_file_name})";

    rapids-make-pip-dependencies ${__rest__[@]} > "${new_env_path}";

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

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(make_pip_env "${DEFAULT_VIRTUAL_ENV:-rapids}" "$@");

if test -f ~/.local/share/venvs/${DEFAULT_VIRTUAL_ENV:-rapids}/bin/activate; then
    . ~/.local/share/venvs/${DEFAULT_VIRTUAL_ENV:-rapids}/bin/activate;
fi
