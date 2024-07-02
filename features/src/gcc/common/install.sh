#! /usr/bin/env bash
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

src="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# export bash utility functions
# shellcheck disable=SC1091
source "$src/utilities.sh";

rm -f /etc/profile.d/00-restore-env.sh;

# install /etc/skel
cp -r "$src/etc/skel" /etc/;
# install /etc/bash.bash_env
cp "$src/etc/bash.bash_env" /etc/;
chown root:root /etc/bash.bash_env;
chmod u+rwx,g+rwx,o+rx /etc/bash.bash_env;

unset src;

# Store and reset BASH_ENV in /etc/profile so lmod doesn't steal it from us.
# Our `/etc/bash.bash_env` will source lmod's $BASH_ENV at the end.
append_to_etc_profile "$(cat <<EOF
export BASH_ENV_ETC_PROFILE="\$BASH_ENV";
export BASH_ENV=/etc/bash.bash_env;
EOF
)";

if ! grep -qE '^BASH_ENV=/etc/bash.bash_env$' /etc/environment; then
    echo "BASH_ENV=/etc/bash.bash_env" >> /etc/environment;
fi

# Remove unnecessary "$HOME/.local/bin" at the end of the path
# shellcheck disable=SC2016
if grep -qxF 'if [[ "${PATH}" != *"$HOME/.local/bin"* ]]; then export PATH="${PATH}:$HOME/.local/bin"; fi' /etc/bash.bashrc; then
   grep -vxF \
    'if [[ "${PATH}" != *"$HOME/.local/bin"* ]]; then export PATH="${PATH}:$HOME/.local/bin"; fi' \
    /etc/bash.bashrc \
    > /etc/bash.bashrc.new \
 && mv /etc/bash.bashrc{.new,};
fi

cp /etc/skel/.profile /root/.profile;
echo 'mesg n 2> /dev/null || true' >> /root/.profile;

for_each_user_profile "$(cat <<"EOF"
sed -i 's@if \[ -d "$HOME/bin" \]@if [ -n "${PATH##*"$HOME/bin"*}" ] \&\& [ -d "$HOME/bin" ]@' $0;
sed -i 's@if \[ -d "$HOME/.local/bin" \]@if [ -n "${PATH##*"$HOME/.local/bin"*}" ] \&\& [ -d "$HOME/.local/bin" ]@' $0;
EOF
)";

# Fix the devcontainers/features/common-utils __bash_prompt fn
# shellcheck disable=SC2016
for_each_user_bashrc '
if [[ "$(grep -qE "^__bash_prompt\(\) \{$" "$0"; echo $?)" == 0 ]]; then
    sed -i "s/\${BRANCH}/\${BRANCH:-}/g" "$0";
    sed -i "s/\${GITHUB_USER}/\${GITHUB_USER:-}/g" "$0";
fi
';
