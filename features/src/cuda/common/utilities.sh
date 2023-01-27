#! /usr/bin/env bash

# Define common shell functions

# Run apt update if apt lists aren't populated
apt_get_update() {
    if [ "$(find /var/lib/apt/lists -mindepth 1 | head -n1 | wc -l)" = "0" ]; then
        echo "Running apt-get update...";
        apt-get update -y;
    fi
}

export -f apt_get_update;

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update;
        echo "Installing packages: $@";
        DEBIAN_FRONTEND=noninteractive \
        apt-get -y install --no-install-recommends "$@";
    fi
}

export -f check_packages;

for_each_user_bashrc() {
    # Update all bashrc files
    find / /etc /home ${_REMOTE_USER_HOME} ${_CONTAINER_USER_HOME} -maxdepth 2 -type f -name .bashrc \
  | sort | uniq | xargs -r -d'\n' -n1 bash -c "${@}";
}

export -f for_each_user_bashrc;

append_to_all_bashrcs() {
    # Update all bashrc files
    for bashrc in $(find / /etc /home ${_REMOTE_USER_HOME} ${_CONTAINER_USER_HOME} -maxdepth 2 -type f -name .bashrc | sort | uniq); do
        if [[ "$(cat "$bashrc")" != *"$1"* ]]; then
            echo "Appending to $bashrc...";
            echo -e "$1" >> "$bashrc";
        fi
    done
}

export -f append_to_all_bashrcs;

prepend_to_all_bashrcs() {
    # Update all bashrc files
    for bashrc in $(find / /etc /home ${_REMOTE_USER_HOME} ${_CONTAINER_USER_HOME} -maxdepth 2 -type f -name .bashrc | sort | uniq); do
        if [[ "$(cat "$bashrc")" != *"$1"* ]]; then
            echo "Prepending to $bashrc...";
            echo -e "$1\n$(cat "$bashrc")" > "$bashrc";
        fi
    done
}

export -f prepend_to_all_bashrcs;

append_to_etc_profile() {
    if [[ "$(cat /etc/profile)" != *"$1"* ]]; then
        echo "Appending to /etc/profile...";
        echo -e "$1" >> /etc/profile;
    fi
}

export -f append_to_etc_profile;

prepend_to_etc_profile() {
    if [[ "$(cat /etc/profile)" != *"$1"* ]]; then
        echo "Prepending to /etc/profile...";
        echo -e "$1\n$(cat /etc/profile)" > /etc/profile;
    fi
}

export -f prepend_to_etc_profile;

append_to_etc_bashrc() {
    if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
        echo "Appending to /etc/bash.bashrc...";
        echo -e "$1" >> /etc/bash.bashrc;
    fi
}

export -f append_to_etc_bashrc;

prepend_to_etc_bashrc() {
    if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
        echo "Prepending to /etc/bash.bashrc...";
        echo -e "$1\n$(cat /etc/bash.bashrc)" > /etc/bash.bashrc;
    fi
}

export -f prepend_to_etc_bashrc;

append_etc_zshrc() {
    if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
        echo "Appending to /etc/zsh/zshrc...";
        echo -e "$1" >> /etc/zsh/zshrc;
    fi
}

export -f append_etc_zshrc;

prepend_to_etc_zshrc() {
    if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
        echo "Prepending to /etc/zsh/zshrc...";
        echo -e "$1\n$(cat /etc/zsh/zshrc)" > /etc/zsh/zshrc;
    fi
}

export -f prepend_to_etc_zshrc;

# Figure out correct version of a three part version number is not passed
find_version_from_git_tags() {
    check_packages git;
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local suffix=${5:-}
    local last_part_optional=${6:-"false"}
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local last_part
        if [ "${last_part_optional}" = "true" ]; then
            last_part="(${escaped_separator}[0-9]+${suffix})?"
        else
            last_part="${escaped_separator}[0-9]+${suffix}"
        fi
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
        local version_list="$(git ls-remote --tags ${repository} | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g ${variable_name}="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            declare -g ${variable_name}="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
    fi
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" > /dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
    echo "${variable_name}=${!variable_name}"
}

export -f find_version_from_git_tags;

# Use semver logic to decrement a version number then look for the closest match
find_prev_version_from_git_tags() {
    local variable_name=$1
    local current_version=${!variable_name}
    local repository=$2
    # Normally a "v" is used before the version number, but support alternate cases
    local prefix=${3:-"tags/v"}
    # Some repositories use "_" instead of "." for version number part separation, support that
    local separator=${4:-"."}
    # Some repositories may have tags that include a suffix (e.g. actions/node-versions)
    local version_suffix_regex=${5:-}
    # Some tools release versions that omit the last digit (e.g. go)
    local last_part_optional=${6:-"false"}
    # Try one break fix version number less if we get a failure. Use "set +e" since "set -e" can cause failures in valid scenarios.
    set +e
        major="$(echo "${current_version}" | grep -oE '^[0-9]+' || echo '')"
        minor="$(echo "${current_version}" | grep -oP '^[0-9]+\.\K[0-9]+' || echo '')"
        breakfix="$(echo "${current_version}" | grep -oP '^[0-9]+\.[0-9]+\.\K[0-9]+' 2>/dev/null || echo '')"

        if [ "${minor}" = "0" ] && [ "${breakfix}" = "0" ]; then
            ((major=major-1))
            declare -g ${variable_name}="${major}"
            # Look for latest version from previous major release
            find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${version_suffix_regex}" "${last_part_optional}"
        # Handle situations like Go's odd version pattern where "0" releases omit the last part
        elif [ "${breakfix}" = "" ] || [ "${breakfix}" = "0" ]; then
            ((minor=minor-1))
            declare -g ${variable_name}="${major}.${minor}"
            # Look for latest version from previous minor release
            find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${version_suffix_regex}" "${last_part_optional}"
        else
            ((breakfix=breakfix-1))
            if [ "${breakfix}" = "0" ] && [ "${last_part_optional}" = "true" ]; then
                declare -g ${variable_name}="${major}.${minor}"
            else
                declare -g ${variable_name}="${major}.${minor}.${breakfix}"
            fi
        fi
    set -e
}

export -f find_prev_version_from_git_tags;

# Determine the appropriate non-root user
find_non_root_user() {
    USERNAME="${USERNAME:-"${_REMOTE_USER:-"auto"}"}";
    if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
        USERNAME=""
        POSSIBLE_USERS=("vscode" "node" "codespace" "coder" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
        for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
            if id -u ${CURRENT_USER} > /dev/null 2>&1; then
                USERNAME=${CURRENT_USER}
                break
            fi
        done
    elif [ "${USERNAME}" = "none" ] || ! id -u "${USERNAME}" > /dev/null 2>&1; then
        USERNAME=root
    fi
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
}

export -f find_non_root_user;
