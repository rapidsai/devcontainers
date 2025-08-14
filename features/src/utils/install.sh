#! /usr/bin/env bash
set -e

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

PKGS=(
    jq
    cron
    curl
    sudo
    wget
    socat
    procps
    tzdata
    gettext-base
    openssh-client
    bash-completion
    ca-certificates
);

if ! command -V python3 >/dev/null 2>&1; then
    PKGS+=(python3 python3-pip);
elif ! python3 -m pip >/dev/null 2>&1; then
    PKGS+=(python3-pip);
fi

check_packages "${PKGS[@]}";

source /etc/lsb-release;

# Upgrade system pip
declare -a _PIP_INSTALL_ARGS=()
declare -a _PIP_UPGRADE_ARGS=(--upgrade)

if [[ "${DISTRIB_RELEASE}" > "22.04" ]]; then
    _PIP_INSTALL_ARGS+=(--break-system-packages);
    if [[ "${DISTRIB_RELEASE}" > "23.04" ]]; then
        _PIP_UPGRADE_ARGS+=(--ignore-installed);
    fi
fi

python3 -m pip install "${_PIP_INSTALL_ARGS[@]}" "${_PIP_UPGRADE_ARGS[@]}" pip;

# Install yq if not installed
if ! command -V yq >/dev/null 2>&1; then
    YQ_BINARY="yq";
    YQ_BINARY+="_$(uname -s | tr '[:upper:]' '[:lower:]')";
    YQ_BINARY+="_${TARGETARCH:-$(dpkg --print-architecture | awk -F'-' '{print $NF}')}";

    YQ_VERSION=4.46.1;
    find_version_from_git_tags YQ_VERSION https://github.com/mikefarah/yq;
    while ! wget --no-hsts -q -O- "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${YQ_BINARY}.tar.gz" | tar -C /usr/bin -zf - -x ./${YQ_BINARY} --transform="s/${YQ_BINARY}/yq/"; do
        echo "(!) YQ version ${YQ_VERSION} failed to download. Attempting to fall back one version to retry...";
        find_prev_version_from_git_tags YQ_VERSION https://github.com/mikefarah/yq;
    done
fi

# Remove built-in anacron configs
# rm -rf /etc/crontab /etc/cron.*;

# Allow crond to be run by users in the "crontab" group
chgrp crontab "$(realpath -m "$(which cron)")";
chmod u+s "$(realpath -m "$(which cron)")";

# shellcheck disable=SC2174
mkdir -m 0777 -p /var/log/devcontainer-utils;
touch /var/log/devcontainer-utils/creds-s3.log;
chmod 0777 /var/log/devcontainer-utils/creds-s3.log;

# Install Devcontainer utility scripts to /opt/devcontainer
cp -ar ./opt/devcontainer /opt/;

declare -a commands_and_sources=(
    "debug-output                       debug-output.sh"
    "parse-args                         parse-args.sh"
    "parse-args-from-docstring          parse-args-from-docstring.sh"
    "bash-completion.tmpl               bash/completion.tmpl.sh"
    "creds-s3-init                      creds/s3/init.sh"
    "creds-s3-generate                  creds/s3/generate.sh"
    "creds-s3-persist                   creds/s3/persist.sh"
    "creds-s3-propagate                 creds/s3/propagate.sh"
    "creds-s3-schedule                  creds/s3/schedule.sh"
    "creds-s3-test                      creds/s3/test.sh"
    "creds-s3-gh-generate               creds/s3/gh/generate.sh"
    "creds-s3-vault-generate            creds/s3/vault/generate.sh"
    "creds-s3-vault-github              creds/s3/vault/github.sh"
    "generate-bash-completion           bash/generate-bash-completion.sh"
    "shell-is-interactive               shell-is-interactive.sh"
    "post-create-command                post-create-command.sh"
    "post-start-command                 post-start-command.sh"
    "post-start-command-entrypoint      post-start-command-entrypoint.sh"
    "post-attach-command                post-attach-command.sh"
    "post-attach-command-entrypoint     post-attach-command-entrypoint.sh"
    "python-repl-startup                python-repl-startup.py"
    "init-git                           git/init.sh"
    "init-git-interactive               git/init-interactive.sh"
    "clone-git-repo                     git/repo/clone.sh"
    "init-ssh-deploy-keys               ssh/init-deploy-keys.sh"
    "init-github-cli                    github/cli/init.sh"
    "clone-github-repo                  github/repo/clone.sh"
    "github-user-scopes                 github/user/scopes.sh"
    "init-gitlab-cli                    gitlab/cli/init.sh"
    "clone-gitlab-repo                  gitlab/repo/clone.sh"
    "print-missing-gitlab-token-warning gitlab/print-missing-token-warning.sh"
    "install-sccache                    sccache/install.sh"
    "start-sccache                      sccache/start.sh"
    "stop-sccache                       sccache/stop.sh"
    "init-sccache-dist                  sccache/dist/init.sh"
    "configure-sccache-dist             sccache/dist/configure.sh"
    "sccache-dist-status                sccache/dist/status.sh"
)

# Install alternatives
for entry in "${commands_and_sources[@]}"; do
    declare -a pair="(${entry})";
    declare cmd="devcontainer-utils-${pair[0]}";
    declare src="/opt/devcontainer/bin/${pair[1]}";
    update-alternatives --install "/usr/bin/${cmd}" "${cmd}" "${src}" 0;
done

declare -a commands="($(for pair in "${commands_and_sources[@]}"; do cut -d' ' -f1 <<< "${pair}"; done))";

# Install bash_completion script
read -ra commands <<< "${commands[*]/#/--command devcontainer-utils-}";
if test "${#commands[@]}" -gt 0; then
    devcontainer-utils-generate-bash-completion                          \
        --out-file /etc/bash_completion.d/devcontainer-utils-completions \
        "${commands[@]}"                                                 \
    ;
fi

find /opt/devcontainer \
    \( -type d -exec chmod 0775 {} \; \
    -o -type f -exec chmod 0755 {} \; \);

# Enable GCC colors
for_each_user_bashrc 'sed -i -re "s/^#(export GCC_COLORS)/\1/g" "$0"';

# Unlimited history size
for_each_user_bashrc 'sed -i -re "s/^(HIST(FILE)?SIZE=).*$/\1/g" "$0"';

# export envvars in bashrc files
append_to_etc_bashrc "$(cat .bashrc)\n\nexport ORIG_PYTHON=$(which python3)";

append_to_all_bashrcs "$(cat .bashrc)\n\nexport ORIG_PYTHON=$(which python3)";

# export envvars in /etc/profile.d
add_etc_profile_d_script devcontainer-utils "$(cat .bashrc)\n\nexport ORIG_PYTHON=$(which python3)";

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
    mkdir -p -m 0755                                      \
        `# Create ~/.cache, i.e. $XDG_CACHE_HOME`         \
        "${dir}"/.cache                                   \
        `# Create ~/.config, i.e. $XDG_CONFIG_HOME`       \
        "${dir}"/.config "${dir}"/.config/{clangd,pip}    \
        `# Create ~/.local/state, i.e. $XDG_STATE_HOME`   \
        "${dir}"/.local "${dir}"/.local/{bin,state,share} \
    # Create or update ~/.ssh/known_hosts
    mkdir -p -m 0700 "${dir}"/.ssh;
    touch "${dir}"/.ssh/known_hosts;
    chmod 644 "${dir}"/.ssh/known_hosts;
    cat <<____EOF >> "${dir}"/.ssh/known_hosts
${known_hosts}
____EOF
done

rm -rf /root/.cache;
rm -rf /root/.local/{bin,state,share};
rm -rf /root/.config/{clangd,pip};

# Find the non-root user
find_non_root_user;

if test -n "${USERNAME:+x}"; then
    USERHOME="$(bash -c "echo ~${USERNAME}")";

    if command -V gh >/dev/null 2>&1; then
        mkdir -p -m 0755                                         \
            "$USERHOME/.local"                                   \
            "$USERHOME/.local/share"                             \
            "$USERHOME/.local/share/gh"                          \
            "$USERHOME/.local/share/gh/extensions"               \
            "$USERHOME/.local/share/gh/extensions/gh-nv-gha-aws" \
            ;
        NV_GHA_AWS_VERSION=latest
        find_version_from_git_tags NV_GHA_AWS_VERSION https://github.com/nv-gha-runners/gh-nv-gha-aws;
        wget --no-hsts -q -O "$USERHOME/.local/share/gh/extensions/gh-nv-gha-aws/gh-nv-gha-aws" \
            "https://github.com/nv-gha-runners/gh-nv-gha-aws/releases/download/v${NV_GHA_AWS_VERSION}/gh-nv-gha-aws_v${NV_GHA_AWS_VERSION}_linux-$(dpkg --print-architecture | awk -F'-' '{print $NF}')";
        chmod 0755 "$USERHOME/.local/share/gh/extensions/gh-nv-gha-aws/gh-nv-gha-aws";
        cat <<EOF >"$USERHOME/.local/share/gh/extensions/gh-nv-gha-aws/manifest.yml"
owner: nv-gha-runners
name: gh-nv-gha-aws
host: github.com
tag: v${NV_GHA_AWS_VERSION}
ispinned: false
path: $USERHOME/.local/share/gh/extensions/gh-nv-gha-aws/gh-nv-gha-aws
EOF
    fi

    # Add user to the crontab group
    usermod -aG crontab "${USERNAME}";
    # Allow user to edit the crontab
    echo "${USERNAME}" >> /etc/cron.allow;
    # Ensure the user owns their homedir
    chown -R "${USERNAME}:${USERNAME}" "${USERHOME}";
fi

# Generate bash completions
if dpkg -s bash-completion >/dev/null 2>&1; then
    if command -V gh >/dev/null 2>&1; then
        gh completion -s bash | tee /etc/bash_completion.d/gh >/dev/null;
    fi
    if command -V glab >/dev/null 2>&1; then
        glab completion -s bash | tee /etc/bash_completion.d/glab >/dev/null;
    fi
fi

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
