#! /usr/bin/env bash

# Define common shell functions

# Assign variable one scope above the caller
# Usage: local "$1" && _upvar $1 "value(s)"
# Param: $1  Variable name to assign value to
# Param: $*  Value(s) to assign.  If multiple values, an array is
#            assigned, otherwise a single value is assigned.
# See: http://fvue.nl/wiki/Bash:_Passing_variables_by_reference
_upvar() {
    if unset -v "$1"; then
        if (( $# == 2 )); then
            eval $1=\"\$2\";
        else
            eval $1=\(\"\${@:2}\"\);
        fi;
    fi
}

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
        echo "Installing packages: $*";
        DEBIAN_FRONTEND=noninteractive \
        apt-get -y install --no-install-recommends "$@";
    fi
}

export -f check_packages;

for_each_user_bashrc() {
    # Update all bashrc files
    # shellcheck disable=SC2086
    find / /etc /home ${_REMOTE_USER_HOME} ${_CONTAINER_USER_HOME} -maxdepth 2 -type f -name .bashrc \
  | sort | uniq | xargs -r -d'\n' -n1 bash -c "${@}";
}

export -f for_each_user_bashrc;

for_each_user_profile() {
    # Update all .profile files
    # shellcheck disable=SC2086
    find / /etc /home ${_REMOTE_USER_HOME} ${_CONTAINER_USER_HOME} -maxdepth 2 -type f -name .profile \
  | sort | uniq | xargs -r -d'\n' -n1 bash -c "${@}";
}

export -f for_each_user_profile;

append_to_all_bashrcs() {
    # Update all bashrc files
    # shellcheck disable=SC2086
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
    # shellcheck disable=SC2086
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

add_etc_profile_d_script() {
    # shellcheck disable=SC2012
    local name="$(($(ls -1q /etc/profile.d/*.sh | wc -l) + 20))-${1}.sh";
    echo -e "#! /usr/bin/env bash\n${*:2}" > "/etc/profile.d/${name}";
    chmod +x "/etc/profile.d/${name}";
}

export -f add_etc_profile_d_script;

# Determine the appropriate non-root user
find_non_root_user() {
    USERNAME="${USERNAME:-"${_REMOTE_USER:-"auto"}"}";
    if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
        USERNAME=""
        POSSIBLE_USERS=("vscode" "node" "codespace" "coder" "$(awk -v val=1001 -F ":" '$3==val{print $1}' /etc/passwd)")
        for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
            if id -u "${CURRENT_USER}" > /dev/null 2>&1; then
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

# shellcheck disable=SC1091
. "$(dirname "$(realpath -m "${BASH_SOURCE[0]}")")/find-version-from-git-tags.sh";

find_version_from_git_tags() {
    check_packages git;
    _find_version_from_git_tags "$@";
}

export -f find_version_from_git_tags;

find_prev_version_from_git_tags() {
    _find_prev_version_from_git_tags "$@";
}

export -f find_prev_version_from_git_tags;
