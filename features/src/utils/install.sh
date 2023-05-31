#! /usr/bin/env bash
set -ex

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages jq cron curl sudo wget gettext-base bash-completion ca-certificates;

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
rm -rf /etc/crontab /etc/cron.*;

# Install Devcontainer utility scripts to /opt/devcontainer
cp -ar ./opt/devcontainer /opt/;

find /opt/devcontainer \
    \( -type d -exec chmod 0775 {} \; \
    -o -type f -exec chmod 0755 {} \; \);

touch /var/log/vault-s3-init.log;
chmod 0777 /var/log/vault-s3-init.log;
chmod 0644 /opt/devcontainer/cron/vault-s3-init;

install_utility() {
    update-alternatives --install "/usr/bin/$1" "$1" "/opt/devcontainer/bin/$2" 0;
}

install_utility devcontainer-utils-parse-args parse-args.sh;
install_utility devcontainer-utils-post-attach-command post-attach-command.sh;
install_utility devcontainer-utils-init-git git/init.sh;
install_utility devcontainer-utils-clone-git-repo git/repo/clone.sh;

install_utility devcontainer-utils-init-github-cli   github/cli/init.sh;
install_utility devcontainer-utils-clone-github-repo github/repo/clone.sh;

install_utility devcontainer-utils-init-gitlab-cli                    gitlab/cli/init.sh;
install_utility devcontainer-utils-clone-gitlab-repo                  gitlab/repo/clone.sh;
install_utility devcontainer-utils-print-missing-gitlab-token-warning gitlab/print-missing-token-warning.sh;

install_utility devcontainer-utils-vault-s3-init     vault/s3/init.sh;
install_utility devcontainer-utils-vault-s3-test     vault/s3/test.sh;
install_utility devcontainer-utils-vault-s3-export   vault/s3/export.sh;
install_utility devcontainer-utils-vault-auth-github vault/auth/github.sh;

# Enable GCC colors
for_each_user_bashrc 'sed -i -re "s/^#(export GCC_COLORS)/\1/g" "$0"';

# Unlimited history size
for_each_user_bashrc 'sed -i -re "s/^(HIST(FILE)?SIZE=).*$/\1/g" "$0"';

# Append history lines as soon as they're entered
append_to_all_bashrcs 'PROMPT_COMMAND="history -a; $PROMPT_COMMAND"';

# export envvars in /etc/profile.d
add_etc_profile_d_script devcontainer-utils "";

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

if [[ -n "$known_hosts" ]]; then
    for_each_user_bashrc "$(cat <<EOF
    home="\$(dirname "\$(realpath -m "\$0")")"       \
 && mkdir -p -m 0700 "\$home/.ssh"                   \
 && echo "$known_hosts" >> "\$home/.ssh/known_hosts" \
 && chmod 644 "\$home/.ssh/known_hosts"              ;
EOF
)";

    find_non_root_user;
    chown -R ${USERNAME}:${USERNAME} "$(bash -c "echo ~${USERNAME}/.ssh")";
fi

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
