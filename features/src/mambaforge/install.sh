#! /usr/bin/env bash
set -e

MAMBAFORGE_VERSION="${VERSION:-latest}";

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages jq git wget bzip2 ca-certificates bash-completion;

echo "Downloading Mambaforge...";

if [[ "$MAMBAFORGE_VERSION" == latest ]]; then
    find_version_from_git_tags MAMBAFORGE_VERSION https://github.com/conda-forge/miniforge "tags/" "." "-[0-9]+" "true";
fi

wget --no-hsts -q -O /tmp/miniforge.sh \
    https://github.com/conda-forge/miniforge/releases/download/${MAMBAFORGE_VERSION}/Mambaforge-${MAMBAFORGE_VERSION}-Linux-$(uname -p).sh;

echo "Installing Mambaforge...";

# Install miniconda
/bin/bash /tmp/miniforge.sh -b -p /opt/conda;

export PATH="/opt/conda/bin:${PATH}";

conda clean --tarballs --index-cache --packages --yes;
find /opt/conda -follow -type f -name '*.a' -delete;
find /opt/conda -follow -type f -name '*.pyc' -delete;
conda clean --force-pkgs-dirs --all --yes;

# Activate conda in /etc/bash.bashrc
append_to_etc_bashrc "$(cat .bashrc)";
# Activate conda in ~/.bashrc
append_to_all_bashrcs "$(cat .bashrc)";

# Update the devcontainers/features/common-utils __bash_prompt fn
# to insert ${CONDA_PROMPT_MODIFIER} into the dev container's PS1
for_each_user_bashrc '
if [[ "$(grep -q "# Codespaces bash prompt theme" "$0"; echo $?)" == 0 ]]; then
    sed -i -re "s@PS1=\"(\\\$\{userpart\} )@PS1=\"\${CONDA_PROMPT_MODIFIER:-}\1@g" "$0";
fi
';

# Update the `__conda_activate` shell function to make a symlink named
# /tmp/.current-conda-env point to the new "$CONDA_PREFIX" each time they
# execute `conda activate <env>` or `conda deactivate`.
#
# We need a stable absolute path for the dev container's Python extension
# settings (defined in devcontainer-feature.json).
sed -i \
    's/\(shell.posix "$@")\)/\1 \&\& sudo ln -nsf "\\${CONDA_PREFIX:-\/opt\/conda}" \/tmp\/.current-conda-env/' \
    /opt/conda/etc/profile.d/conda.sh;

ln -s /opt/conda /tmp/.current-conda-env;

# Clean up
rm -rf "/tmp/*";
rm -rf "/var/tmp/*";
rm -rf "/var/cache/apt/*";
rm -rf "/var/lib/apt/lists/*";
