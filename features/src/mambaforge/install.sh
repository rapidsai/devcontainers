#! /usr/bin/env bash
set -e

MINIFORGE_VERSION="${VERSION:-latest}";

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
# shellcheck disable=SC1091
. ./common/install.sh;

check_packages jq git wget bzip2 ca-certificates bash-completion;

echo "Downloading Miniforge...";

if [[ "$MINIFORGE_VERSION" == latest ]]; then
    find_version_from_git_tags MINIFORGE_VERSION https://github.com/conda-forge/miniforge "tags/" "." "-[0-9]+" "true";
fi

wget --no-hsts -q -O /tmp/miniforge.sh \
    "https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Miniforge3-${MINIFORGE_VERSION}-Linux-$(uname -p).sh";
echo "Installing Miniforge...";

# Install Miniforge
rm -rf /opt/conda;
/bin/bash /tmp/miniforge.sh -b -p /opt/conda;

export PATH="/opt/conda/bin:${PATH}";

conda update -n base -c conda-forge conda conda-libmamba-solver;
conda clean --tarballs --index-cache --packages --yes;
find /opt/conda -follow -type f -name '*.a' -delete;
find /opt/conda -follow -type f -name '*.pyc' -delete;
conda clean --force-pkgs-dirs --all --yes;

# Activate conda in /etc/bash.bashrc
append_to_etc_bashrc "$(cat<< EOF
for x in "conda" "mamba"; do
    if ! command -V \$x 2>&1 | grep -q function; then . /opt/conda/etc/profile.d/\$x.sh; fi;
done
$(cat .bashrc)
EOF
)";
# Activate conda in ~/.bashrc
append_to_all_bashrcs "$(cat<< EOF
for x in "conda" "mamba"; do
    if ! command -V \$x 2>&1 | grep -q function; then . /opt/conda/etc/profile.d/\$x.sh; fi;
done
$(cat .bashrc)
EOF
)";

# export envvars in /etc/profile.d

# Create and/or replace mamba.sh with a version that doesn't print warnings to stdout (https://github.com/mamba-org/mamba/pull/3788)
# This also protects us when mamba decides to remove this file, which is a decision that is incompatible with this feature.
cat <<"EOF" > /opt/conda/etc/profile.d/mamba.sh
if [ -z "${MAMBA_ROOT_PREFIX:-}" ]; then
    export MAMBA_ROOT_PREFIX="${CONDA_PREFIX:-/opt/conda}"
fi
__mamba_setup="$("/opt/conda/bin/mamba" shell hook --shell posix 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias mamba="/opt/conda/bin/mamba"  # Fallback on help from mamba activate
fi
unset __mamba_setup
EOF

chmod +x /opt/conda/etc/profile.d/mamba.sh;

ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/$(($(ls -1q /etc/profile.d/*.sh | wc -l) + 20))-conda.sh;
ln -s /opt/conda/etc/profile.d/mamba.sh /etc/profile.d/$(($(ls -1q /etc/profile.d/*.sh | wc -l) + 20))-mamba.sh;
add_etc_profile_d_script miniforge "$(cat .bashrc)";

# Update the devcontainers/features/common-utils __bash_prompt fn
# to insert ${CONDA_PROMPT_MODIFIER} into the dev container's PS1
# shellcheck disable=SC2016
for_each_user_bashrc '
if [[ "$(grep -qE "^__bash_prompt\(\) \{$" "$0"; echo $?)" == 0 ]]; then
    sed -i -re "s@PS1=\"(\\\$\{userpart\} )@PS1=\"\${CONDA_PROMPT_MODIFIER:-}\1@g" "$0";
fi
';

# Update the `__conda_activate` shell function to make a symlink named
# /tmp/.current-conda-env point to the new "$CONDA_PREFIX" each time they
# execute `conda activate <env>` or `conda deactivate`.
#
# We need a stable absolute path for the dev container's Python extension
# settings (defined in devcontainer-feature.json).
# shellcheck disable=SC2016
sed -i \
    's/\(shell.posix "$@")\)/\1 \&\& sudo ln -nsf "\\${CONDA_PREFIX:-\/opt\/conda}" \/tmp\/.current-conda-env/' \
    /opt/conda/etc/profile.d/conda.sh;

ln -s /opt/conda /tmp/.current-conda-env;

# Ensure the `~/.conda` dir exists for each user
# shellcheck disable=SC2016
for dir in $(for_each_user_bashrc 'echo "$(dirname "$(realpath -m "$0")")"'); do
    mkdir -p "${dir}"/.conda/{envs,pkgs};
done

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;

rm -rf /tmp/miniforge.sh;
