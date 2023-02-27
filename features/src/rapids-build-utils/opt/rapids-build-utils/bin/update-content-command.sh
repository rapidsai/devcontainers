#! /usr/bin/env -S bash -Eeuo pipefail

mkdir -m 0755 -p ~/{.aws,.cache,.conda,.config};

rapids-generate-scripts;

if [[ "${PYTHON_PACKAGE_MANAGER:-}" == "pip" ]]; then
    _activate_venv=$(cat<<"EOF"
if [[ -f ~/.local/share/venvs/${DEFAULT_VIRTUAL_ENV:-rapids}/bin/activate ]]; then
    . ~/.local/share/venvs/${DEFAULT_VIRTUAL_ENV:-rapids}/bin/activate;
fi
EOF
);
    if [[ "$(cat ~/.bashrc)" != *"$_activate_venv"* ]]; then
        echo "$_activate_venv" >> ~/.bashrc;
    fi
    unset _activate_venv;
fi
