#! /usr/bin/env bash
set -ex

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages jq cron curl gettext-base bash-completion

# Remove built-in anacron configs
rm -rf /etc/crontab /etc/cron.*;

# Install Devcontainer utility scripts to /opt/devcontainer
cp -ar ./opt/devcontainer /opt/;

find /opt/devcontainer \
    \( -type d -exec chmod 0775 {} \; \
    -o -type f -exec chmod 0755 {} \; \);

chmod 0644 /opt/devcontainer/cron/vault-s3-init;

update-alternatives --install /usr/bin/on-create-command       on-create-command      /opt/devcontainer/bin/on-create-command.sh       0
update-alternatives --install /usr/bin/post-attach-command     post-attach-command    /opt/devcontainer/bin/post-attach-command.sh     0
update-alternatives --install /usr/bin/post-start-command      post-start-command     /opt/devcontainer/bin/post-start-command.sh      0
update-alternatives --install /usr/bin/update-content-command  update-content-command /opt/devcontainer/bin/update-content-command.sh  0
update-alternatives --install /usr/bin/github-cli-init         github-cli-init        /opt/devcontainer/bin/github/cli/init.sh         0
update-alternatives --install /usr/bin/gitlab-cli-init         gitlab-cli-init        /opt/devcontainer/bin/gitlab/cli/init.sh         0
update-alternatives --install /usr/bin/gitlab-repo-clone       gitlab-repo-clone      /opt/devcontainer/bin/gitlab/repo/clone.sh       0
update-alternatives --install /usr/bin/github-repo-clone       github-repo-clone      /opt/devcontainer/bin/github/repo/clone.sh       0
update-alternatives --install /usr/bin/vault-s3-init           vault-s3-init          /opt/devcontainer/bin/vault/s3/init.sh           0
update-alternatives --install /usr/bin/vault-s3-test           vault-s3-test          /opt/devcontainer/bin/vault/s3/test.sh           0

# Install aws-curl helper (https://github.com/sormy/aws-curl)
curl -s -o /usr/bin/aws-curl \
    https://raw.githubusercontent.com/sormy/aws-curl/ddbb3ddd24eff32d6d5ad40e9ff0deffa7e74e6a/aws-curl \
 && chmod +x /usr/bin/aws-curl;

# Enable GCC colors
for_each_user_bashrc 'sed -i -re "s/^#(export GCC_COLORS)/\1/g" "$0"';

# Unlimited history size
for_each_user_bashrc 'sed -i -re "s/^(HIST(FILE)?SIZE=).*$/\1/g" "$0"';

# Append history lines as soon as they're entered
for_each_user_bashrc 'echo "PROMPT_COMMAND=\"history -a; \$PROMPT_COMMAND\"" >> "$0"';

# Add GitHub's public keys to known_hosts
for_each_user_bashrc "$(cat <<"EOF"
    home="$(dirname "$0")"                                \
 && mkdir -p -m 0700 "$home/.ssh"                         \
 && json="$(curl https://api.github.com/meta || echo "")" \
 && echo "${json:-'{ "ssh_keys": [] }'}"                  \
  | jq -r '.ssh_keys | map("github.com \(.)") | .[]'      \
  > "$home/.ssh/known_hosts"                              \
 && chmod 644 "$home/.ssh/known_hosts"                    ;
EOF
)"

find_non_root_user;
chown -R ${USERNAME}:${USERNAME} "$(bash -c "echo ~${USERNAME}")";

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
rm -rf "/tmp/*";
rm -rf "/var/tmp/*";
rm -rf "/var/cache/apt/*";
rm -rf "/var/lib/apt/lists/*";
