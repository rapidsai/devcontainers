#! /usr/bin/env bash
set -e

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages      \
    jq              \
    cron            \
    curl            \
    sudo            \
    wget            \
    socat           \
    tzdata          \
    gettext-base    \
    openssh-client  \
    bash-completion \
    ca-certificates ;

source /etc/lsb-release;

if [[ ! "23.04" > "${DISTRIB_RELEASE}" ]]; then
  BREAK_PACKAGES="--break-system-packages";
fi

# upgrade pip
if type python >/dev/null 2>&1; then
    python -m pip install $BREAK_PACKAGES -U pip;
fi

# Install yq if not installed
if ! type yq >/dev/null 2>&1; then
    YQ_BINARY="yq";
    YQ_BINARY+="_$(uname -s | tr '[:upper:]' '[:lower:]')";
    YQ_BINARY+="_${TARGETARCH:-$(dpkg --print-architecture | awk -F'-' '{print $NF}')}";

    YQ_VERSION=latest;
    find_version_from_git_tags YQ_VERSION https://github.com/mikefarah/yq;
    while ! wget --no-hsts -q -O- "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${YQ_BINARY}.tar.gz" | tar -C /usr/bin -zf - -x ./${YQ_BINARY} --transform="s/${YQ_BINARY}/yq/"; do
        echo "(!) YQ version ${YQ_VERSION} failed to download. Attempting to fall back one version to retry...";
        find_prev_version_from_git_tags YQ_VERSION https://github.com/mikefarah/yq;
    done
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

declare -a commands_and_sources=(
    "debug-output                       debug-output.sh"
    "parse-args                         parse-args.sh"
    "parse-args-from-docstring          parse-args-from-docstring.sh"
    "bash-completion.tmpl               bash/completion.tmpl.sh"
    "generate-bash-completion           bash/generate-bash-completion.sh"
    "shell-is-interactive               shell-is-interactive.sh"
    "post-create-command                post-create-command.sh"
    "post-attach-command                post-attach-command.sh"
    "post-attach-command-entrypoint     post-attach-command-entrypoint.sh"
    "python-repl-startup                python-repl-startup.py"
    "init-git                           git/init.sh"
    "clone-git-repo                     git/repo/clone.sh"
    "init-ssh-deploy-keys               ssh/init-deploy-keys.sh"
    "init-github-cli                    github/cli/init.sh"
    "clone-github-repo                  github/repo/clone.sh"
    "init-gitlab-cli                    gitlab/cli/init.sh"
    "clone-gitlab-repo                  gitlab/repo/clone.sh"
    "print-missing-gitlab-token-warning gitlab/print-missing-token-warning.sh"
    "vault-auth-github                  vault/auth/github.sh"
    "vault-s3-init                      vault/s3/init.sh"
    "vault-s3-creds-generate            vault/s3/creds/generate.sh"
    "vault-s3-creds-persist             vault/s3/creds/persist.sh"
    "vault-s3-creds-propagate           vault/s3/creds/propagate.sh"
    "vault-s3-creds-schedule            vault/s3/creds/schedule.sh"
    "vault-s3-creds-test                vault/s3/creds/test.sh"
)

# Install alternatives
for entry in "${commands_and_sources[@]}"; do
    declare -a pair=(${entry});
    declare cmd="devcontainer-utils-${pair[0]}";
    declare src="/opt/devcontainer/bin/${pair[1]}";
    update-alternatives --install /usr/bin/${cmd} ${cmd} ${src} 0;
done

declare -a commands="($(for pair in "${commands_and_sources[@]}"; do cut -d' ' -f1 <<< "${pair}"; done))";

# Install bash_completion script
devcontainer-utils-generate-bash-completion                          \
    --out-file /etc/bash_completion.d/devcontainer-utils-completions \
    ${commands[@]/#/--command devcontainer-utils-}                   \
;

find /opt/devcontainer \
    \( -type d -exec chmod 0775 {} \; \
    -o -type f -exec chmod 0755 {} \; \);

# Enable GCC colors
for_each_user_bashrc 'sed -i -re "s/^#(export GCC_COLORS)/\1/g" "$0"';

# Unlimited history size
for_each_user_bashrc 'sed -i -re "s/^(HIST(FILE)?SIZE=).*$/\1/g" "$0"';

# export envvars in bashrc files
append_to_etc_bashrc "$(cat .bashrc)";
append_to_all_bashrcs "$(cat .bashrc)";

# export envvars in /etc/profile.d
add_etc_profile_d_script devcontainer-utils "$(cat .bashrc)";

# Add GitHub's key fingerprints to known_hosts (curl -s https://api.github.com/meta | jq -r '.ssh_keys | map("github.com \(.)") | .[]')
# Add GitLab's key fingerprints to known_hosts (https://docs.gitlab.com/ee/user/gitlab_com/index.html#ssh-known_hosts-entries)
known_hosts="$(cat <<EOF
github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
github.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEmKSENjQEezOmxkZMy7opKgwFB9nkt5YRrYMjNuG5N87uRgg6CLrbo5wAdT/y6v0mKV0U2w0WZ2YB/++Tpockg=
github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
gitlab.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf
gitlab.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi/ueaBMCvbcTHhO7FcwzY92WK4Yt0aGROY5qX2UKSeOvuP4D6TPqKF1onrSzH9bx9XUf2lEdWT/ia1NEKjunUqu1xOB/StKDHMoX4/OKyIzuS0q/T1zOATthvasJFoPrAjkohTyaDUz2LN5JoH839hViyEG82yB+MjcFV5MU3N1l1QL3cVUCh93xSaua1N85qivl+siMkPGbO5xR/En4iEY6K2XPASUEMaieWVNTRCtJ4S8H+9
gitlab.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGjeR4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY=
EOF
)";

# shellcheck disable=SC2174
for dir in $(for_each_user_bashrc 'echo "$(dirname "$(realpath -m "$0")")"'); do
    # Copy in default git config
    rm -f "${dir}"/.gitconfig;
    cp .gitconfig "${dir}"/.gitconfig.default;
    # Copy in default .bash_completion
    cp .bash_completion "${dir}"/.bash_completion;
    mkdir -p -m 0755                                    \
        `# Create ~/.cache, i.e. $XDG_CACHE_HOME`       \
        "${dir}"/.cache                                 \
        `# Create ~/.config, i.e. $XDG_CONFIG_HOME`     \
        "${dir}"/.config "${dir}"/.config/{clangd,pip}  \
        `# Create ~/.local/state, i.e. $XDG_STATE_HOME` \
        "${dir}"/.local "${dir}"/.local/{bin,state}     \
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

if test -n "${USERNAME-}"; then
    USERHOME="$(bash -c "echo ~${USERNAME-}")";
    # Add user to the crontab group
    usermod -aG crontab "${USERNAME}";
    # Allow user to edit the crontab
    echo "${USERNAME}" >> /etc/cron.allow;
    # Ensure the user owns their homedir
    chown -R "${USERNAME}:${USERNAME}" "${USERHOME}";
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
