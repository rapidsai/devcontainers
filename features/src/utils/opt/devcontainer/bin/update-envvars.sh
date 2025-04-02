#! /usr/bin/env bash

override_envvar() {
    if test -n "${1:+x}"; then
        for file in ~/.bashrc /etc/profile.d/*-devcontainer-utils.sh; do
            cat <<< "export ${1}=\"${2:-}\";" | sudo tee -a "${file}" >/dev/null;
        done;
    fi
}

export_envvar() {
    if test -n "${1:+x}"; then
        for file in ~/.bashrc /etc/profile.d/*-devcontainer-utils.sh; do
            cat <<< "if test -v ${1}; then export ${1}=\"${2:-}\"; fi" | sudo tee -a "${file}" >/dev/null;
        done;
    fi
}

unset_envvar() {
    if test -n "${1:+x}"; then
        for file in ~/.bashrc /etc/profile.d/*-devcontainer-utils.sh; do
            cat <<< "unset ${1};" | sudo tee -a "${file}" >/dev/null;
        done;
    fi
}

reset_envvar() {
    if test -n "${1:+x}"; then
        for file in ~/.bashrc /etc/profile.d/*-devcontainer-utils.sh; do
            if grep -q -E "^unset ${1};\$" "${file}"; then
                sudo sed -Ei "/^unset ${1};\$/d" "${file}";
            fi
            if grep -q -E "^export ${1}=.*$" "${file}"; then
                sudo sed -Ei "/^export ${1}=.*\$/d" "${file}";
            fi
            if grep -q -E "^if test -v ${1}; then export ${1}=.*$" "${file}"; then
                sudo sed -Ei "/^if test -v ${1}; then export ${1}=.*\$/d" "${file}";
            fi
        done
    fi
}
