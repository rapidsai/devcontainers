#! /usr/bin/env bash
set -ex

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages                  \
    jq                          \
    gettext-base                \
    bash-completion             \
    ;

# Install yq if not installed
if ! dpkg -s "yq" > /dev/null 2>&1; then
    check_packages                 \
        wget                       \
        gpg-agent                  \
        software-properties-common \
        ;
    wget --no-hsts -q -O- "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x9a2d61f6bb03ced7522b8e7d6657dbe0cc86bb64" \
        | gpg --dearmor -o /etc/apt/trusted.gpg.d/rmescandon-yq-archive-keyring.gpg;
    chmod 0644 /etc/apt/trusted.gpg.d/*.gpg;
    apt-add-repository -y ppa:rmescandon/yq;
    check_packages yq;
fi

# Install the rapids dependency file generator and conda-merge
if type python >/dev/null 2>&1; then
    python -m pip install rapids-dependency-file-generator conda-merge;
fi

# Install RAPIDS build utility scripts to /opt/

cp -ar ./opt/rapids-build-utils /opt/;

update-alternatives --install /usr/bin/rapids-generate-scripts           rapids-generate-scripts           /opt/rapids-build-utils/bin/generate-scripts.sh           0;
update-alternatives --install /usr/bin/rapids-join-strings               rapids-join-strings               /opt/rapids-build-utils/bin/join-strings.sh               0;
update-alternatives --install /usr/bin/rapids-make-conda-env             rapids-make-conda-env             /opt/rapids-build-utils/bin/make-conda-env.sh             0;
update-alternatives --install /usr/bin/rapids-make-pip-env               rapids-make-pip-env               /opt/rapids-build-utils/bin/make-pip-env.sh               0;
update-alternatives --install /usr/bin/rapids-make-vscode-workspace      rapids-make-vscode-workspace      /opt/rapids-build-utils/bin/make-vscode-workspace.sh      0;
update-alternatives --install /usr/bin/rapids-parse-cmake-args           rapids-parse-cmake-args           /opt/rapids-build-utils/bin/parse-cmake-args.sh           0;
update-alternatives --install /usr/bin/rapids-parse-cmake-build-type     rapids-parse-cmake-build-type     /opt/rapids-build-utils/bin/parse-cmake-build-type.sh     0;
update-alternatives --install /usr/bin/rapids-parse-cmake-var-from-args  rapids-parse-cmake-var-from-args  /opt/rapids-build-utils/bin/parse-cmake-var-from-args.sh  0;
update-alternatives --install /usr/bin/rapids-parse-cmake-vars-from-args rapids-parse-cmake-vars-from-args /opt/rapids-build-utils/bin/parse-cmake-vars-from-args.sh 0;
update-alternatives --install /usr/bin/rapids-python-pkg-roots           rapids-python-pkg-roots           /opt/rapids-build-utils/bin/python-pkg-roots.sh           0;
update-alternatives --install /usr/bin/rapids-python-pkg-names           rapids-python-pkg-names           /opt/rapids-build-utils/bin/python-pkg-names.sh           0;
update-alternatives --install /usr/bin/rapids-python-conda-pkg-names     rapids-python-conda-pkg-names     /opt/rapids-build-utils/bin/python-conda-pkg-names.sh     0;

find /opt/rapids-build-utils \
    \( -type d -exec chmod 0775 {} \; \
    -o -type f -exec chmod 0755 {} \; \);

# Copy in bash completions
mkdir -p /etc/bash_completion.d/;
cp -ar ./etc/bash_completion.d/* /etc/bash_completion.d/;

yq shell-completion bash | tee /etc/bash_completion.d/yq >/dev/null;

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
