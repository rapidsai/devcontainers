#! /usr/bin/env bash

# This test can be run with the following command (from the root of this repo)
# ```
# npx --package=@devcontainers/cli -c 'devcontainer features test \
#     --features cuda \
#     --base-image ubuntu:22.04 .'
# ```

set -e

# Optional: Import test library bundled with the devcontainer CLI
source dev-container-features-test-lib

# Feature-specific tests
# The 'check' command comes from the dev-container-features-test-lib.
check "post-attach-command.sh exists" stat /opt/devcontainer/bin/post-attach-command.sh

eval "$(ssh-agent -s)";

# Generate and add all sorts of keys/urls to the SSH agent
for type in dsa rsa ecdsa ed25519; do
    ssh-keygen -q -N "" -t "${type}" -f ~/.ssh/id_${type}_1 -C "git@github.com:rapidsai/devcontainers.git";
    ssh-keygen -q -N "" -t "${type}" -f ~/.ssh/id_${type}_2 -C "https://github.com/rapidsai/devcontainers";
    ssh-keygen -q -N "" -t "${type}" -f ~/.ssh/id_${type}_3 -C "https://github.com/rapidsai/devcontainers.git";
    ssh-keygen -q -N "" -t "${type}" -f ~/.ssh/id_${type}_4 -C "ssh://git@github.com:rapidsai/devcontainers.git";
    ssh-add -q ~/.ssh/id_${type}_1 ~/.ssh/id_${type}_2 ~/.ssh/id_${type}_3 ~/.ssh/id_${type}_4;
done

devcontainer-utils-init-ssh-deploy-keys;

re="(ssh:\/\/|https:\/\/)?(git@)?(.*\.com)[:\/](.*)";

# Verify the `devcontainer-utils-init-ssh-deploy-keys` script configured Git and SSH correctly
for type in dsa rsa ecdsa ed25519; do
    for i in 1 2 3 4; do
        key="$(cut -d' ' -f2 < ~/.ssh/id_${type}_${i}.pub)";
        url="$(cut -d' ' -f3 < ~/.ssh/id_${type}_${i}.pub)";
        sha="$(md5sum --tag <<< "${key}" | cut -d' ' -f4)";
        if [[ ${url} =~ ${re} ]]; then
            host="${BASH_REMATCH[3]}";
            repo="${BASH_REMATCH[4]//.git/}";
            file="$HOME/.ssh/key-${sha}.pub";
            check "id_${type}_${i}: public key exists" test -f "${file}";
            check "id_${type}_${i}: ssh config has entry" grep -qE "^Host key-${sha}.${host}$" ~/.ssh/config;
            check "id_${type}_${i}: gitconfig has entry" grep -qE "^\[url \"git@key\-${sha}.${host}:${repo}\"\]$" ~/.gitconfig;
        else
            check "${url} does not match regex" false;
        fi
    done
done

# Report result
# If any of the checks above exited with a non-zero exit code, the test will fail.
reportResults
