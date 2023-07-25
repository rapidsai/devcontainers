#! /usr/bin/env bash
set -ex

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages jq cron curl sudo wget tzdata gettext-base bash-completion ca-certificates;

# Install yq if not installed
if ! type yq >/dev/null 2>&1; then
    YQ_VERSION=latest;
    find_version_from_git_tags YQ_VERSION https://github.com/mikefarah/yq;

    YQ_BINARY="yq";
    YQ_BINARY+="_$(uname -s | tr '[:upper:]' '[:lower:]')";
    YQ_BINARY+="_${TARGETARCH:-$(dpkg --print-architecture | awk -F'-' '{print $NF}')}";

    wget --no-hsts -q -O- "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${YQ_BINARY}.tar.gz" \
        | tar -C /usr/bin -zf - -x ./${YQ_BINARY} --transform="s/${YQ_BINARY}/yq/";
fi

# Remove built-in anacron configs
# rm -rf /etc/crontab /etc/cron.*;

# Allow crond to be run by users in the "crontab" group
chgrp crontab "$(realpath -m $(which cron))";
chmod u+s "$(realpath -m $(which cron))";

touch /var/log/devcontainer-utils-vault-s3-creds-refresh.log;
chmod 0664 /var/log/devcontainer-utils-vault-s3-creds-refresh.log;
chgrp crontab /var/log/devcontainer-utils-vault-s3-creds-refresh.log;

# Install Devcontainer utility scripts to /opt/devcontainer
cp -ar ./opt/devcontainer /opt/;

find /opt/devcontainer \
    \( -type d -exec chmod 0775 {} \; \
    -o -type f -exec chmod 0755 {} \; \);

install_utility() {
    update-alternatives --install "/usr/bin/$1" "$1" "/opt/devcontainer/bin/$2" 0;
}

install_utility devcontainer-utils-parse-args parse-args.sh;
install_utility devcontainer-utils-shell-is-interactive shell-is-interactive.sh;
install_utility devcontainer-utils-post-attach-command post-attach-command.sh;
install_utility devcontainer-utils-post-attach-command-entrypoint post-attach-command-entrypoint.sh;
install_utility devcontainer-utils-python-repl-startup python-repl-startup.py;
install_utility devcontainer-utils-init-git git/init.sh;
install_utility devcontainer-utils-clone-git-repo git/repo/clone.sh;

install_utility devcontainer-utils-init-github-cli   github/cli/init.sh;
install_utility devcontainer-utils-clone-github-repo github/repo/clone.sh;

install_utility devcontainer-utils-init-gitlab-cli                    gitlab/cli/init.sh;
install_utility devcontainer-utils-clone-gitlab-repo                  gitlab/repo/clone.sh;
install_utility devcontainer-utils-print-missing-gitlab-token-warning gitlab/print-missing-token-warning.sh;

install_utility devcontainer-utils-vault-auth-github vault/auth/github.sh;

install_utility devcontainer-utils-vault-s3-init            vault/s3/init.sh;
install_utility devcontainer-utils-vault-s3-creds-generate  vault/s3/creds/generate.sh;
install_utility devcontainer-utils-vault-s3-creds-persist   vault/s3/creds/persist.sh;
install_utility devcontainer-utils-vault-s3-creds-propagate vault/s3/creds/propagate.sh;
install_utility devcontainer-utils-vault-s3-creds-schedule  vault/s3/creds/schedule.sh;
install_utility devcontainer-utils-vault-s3-creds-test      vault/s3/creds/test.sh;

# Enable GCC colors
for_each_user_bashrc 'sed -i -re "s/^#(export GCC_COLORS)/\1/g" "$0"';

# Unlimited history size
for_each_user_bashrc 'sed -i -re "s/^(HIST(FILE)?SIZE=).*$/\1/g" "$0"';

# export envvars in bashrc files
append_to_etc_bashrc "$(cat .bashrc)";
append_to_all_bashrcs "$(cat .bashrc)";

# export envvars in /etc/profile.d
add_etc_profile_d_script devcontainer-utils "$(cat .bashrc)";

known_hosts="";
# Add GitHub's key fingerprints to known_hosts
known_hosts="$(curl -s https://api.github.com/meta | jq -r '.ssh_keys | map("github.com \(.)") | .[]' || echo "")";
# Add GitLab's key fingerprints to known_hosts
known_hosts+="$(cat <<EOF
# https://docs.gitlab.com/ee/user/gitlab_com/index.html#ssh-known_hosts-entries
gitlab.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf
gitlab.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi/ueaBMCvbcTHhO7FcwzY92WK4Yt0aGROY5qX2UKSeOvuP4D6TPqKF1onrSzH9bx9XUf2lEdWT/ia1NEKjunUqu1xOB/StKDHMoX4/OKyIzuS0q/T1zOATthvasJFoPrAjkohTyaDUz2LN5JoH839hViyEG82yB+MjcFV5MU3N1l1QL3cVUCh93xSaua1N85qivl+siMkPGbO5xR/En4iEY6K2XPASUEMaieWVNTRCtJ4S8H+9
gitlab.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGjeR4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY=
EOF
)";

for dir in $(for_each_user_bashrc 'echo "$(dirname "$(realpath -m "$0")")"'); do
    # Copy in default git config
    rm -f "${dir}"/.gitconfig;
    cp .gitconfig "${dir}"/.gitconfig.default;
    # Create ~/.cache, i.e. $XDG_CACHE_HOME
    mkdir -p -m 0755 "${dir}"/.cache;
    # Create ~/.cache, i.e. $XDG_CONFIG_HOME
    mkdir -p -m 0755 "${dir}"/.config/{clangd,pip};
    # Create ~/.local/state, i.e. $XDG_STATE_HOME
    mkdir -p -m 0755 "${dir}"/.local/state;
    # Create or update ~/.ssh/known_hosts
    mkdir -p -m 0700 "${dir}"/.ssh;
    touch "${dir}"/.ssh/known_hosts;
    chmod 644 "${dir}"/.ssh/known_hosts;
    cat <<____EOF >> "${dir}"/.ssh/known_hosts
${known_hosts}
____EOF
done

rm -rf /root/.cache;
rm -rf /root/.local/{bin,state};
rm -rf /root/.config/{clangd,pip};

# Find the non-root user
find_non_root_user;

USERHOME="$(bash -c "echo ~${USERNAME}")";

# Add user to the crontab group
usermod -aG crontab "${USERNAME}";

# Allow user to edit the crontab
echo "${USERNAME}" >> /etc/cron.allow;

# Create ~/.cache, i.e. $XDG_CONFIG_HOME
mkdir -p -m 0755 "${USERHOME}"/.local/bin;

# Ensure the user owns their homedir
chown -R "${USERNAME}:${USERNAME}" "${USERHOME}";

# Generate bash completions
if dpkg -s bash-completion >/dev/null 2>&1; then
    if type gh >/dev/null 2>&1; then
        gh completion -s bash | tee /etc/bash_completion.d/gh >/dev/null;
    fi
    if type glab >/dev/null 2>&1; then
        glab completion -s bash | tee /etc/bash_completion.d/glab >/dev/null;
    fi
fi

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
