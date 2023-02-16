#! /usr/bin/env bash
set -e

# Ensure we're in this feature's directory during build
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";

# install global/common scripts
. ./common/install.sh;

check_packages jq curl gettext-base bash-completion

# Install the rapids dependency file generator and conda-merge
/opt/conda/bin/pip install rapids-dependency-file-generator conda-merge;

# Install RAPIDS devcontainer utility scripts to /opt/

cp -ar ./opt/rapids /opt/;

update-alternatives --install /usr/bin/rapids-generate-scripts           rapids-generate-scripts           /opt/rapids/bin/generate-scripts.sh           0;
update-alternatives --install /usr/bin/rapids-join-strings               rapids-join-strings               /opt/rapids/bin/join-strings.sh               0;
update-alternatives --install /usr/bin/rapids-make-conda-env             rapids-make-conda-env             /opt/rapids/bin/make-conda-env.sh             0;
update-alternatives --install /usr/bin/rapids-make-pip-env               rapids-make-pip-env               /opt/rapids/bin/make-pip-env.sh               0;
update-alternatives --install /usr/bin/rapids-make-vscode-workspace      rapids-make-vscode-workspace      /opt/rapids/bin/make-vscode-workspace.sh      0;
update-alternatives --install /usr/bin/rapids-parse-cmake-args           rapids-parse-cmake-args           /opt/rapids/bin/parse-cmake-args.sh           0;
update-alternatives --install /usr/bin/rapids-parse-cmake-build-type     rapids-parse-cmake-build-type     /opt/rapids/bin/parse-cmake-build-type.sh     0;
update-alternatives --install /usr/bin/rapids-parse-cmake-var-from-args  rapids-parse-cmake-var-from-args  /opt/rapids/bin/parse-cmake-var-from-args.sh  0;
update-alternatives --install /usr/bin/rapids-parse-cmake-vars-from-args rapids-parse-cmake-vars-from-args /opt/rapids/bin/parse-cmake-vars-from-args.sh 0;
update-alternatives --install /usr/bin/rapids-python-pkg-roots           rapids-python-pkg-roots           /opt/rapids/bin/python-pkg-roots.sh           0;
update-alternatives --install /usr/bin/rapids-python-pkg-names           rapids-python-pkg-names           /opt/rapids/bin/python-pkg-names.sh           0;

generate_clone_script() {
    local lib="${1:-}";
    local src="${2:-}";
    local deps="${3:-}";
    local args="${4:-}";

    cat<<EOF > "/opt/rapids/bin/clone-${lib}.sh"
if [[ ! -d ~/'${lib}/.git' ]]; then
    echo 'Cloning ${lib}' 1>&2;
    github-repo-clone 'rapidsai' '${lib}' '${lib}';
    rapids-generate-scripts '${lib}' '${src}' '${deps}' '${args}';
    rapids-make-vscode-workspace > ~/workspace.code-workspace;
fi
EOF

    update-alternatives --install \
        "/usr/bin/clone-${lib}" "clone-${lib}" "/opt/rapids/bin/clone-${lib}.sh" 0;
}

gen_rmm_args='          rmm                                              ';
gen_cudf_args='         cudf         cpp "rmm"                           ';
gen_raft_args='         raft         cpp "rmm"                           ';
gen_cumlprims_mg_args=' cumlprims_mg cpp "rmm raft/cpp"                  ';
gen_cuml_args='         cuml         cpp "rmm raft/cpp cumlprims_mg/cpp" ';
gen_cugraph_ops_args='  cugraph-ops  cpp "rmm raft/cpp"                  ';
gen_cugraph_args='      cugraph      cpp "rmm raft/cpp cugraph-ops/cpp"  ';
gen_cuspatial_args='    cuspatial    cpp "rmm cudf/cpp"                  ';

generate_clone_script ${gen_rmm_args};
generate_clone_script ${gen_cudf_args};
generate_clone_script ${gen_raft_args};
generate_clone_script ${gen_cumlprims_mg_args};
generate_clone_script ${gen_cuml_args};
generate_clone_script ${gen_cugraph_ops_args};
generate_clone_script ${gen_cugraph_args};
generate_clone_script ${gen_cuspatial_args};

cat<<EOF >> /opt/rapids/bin/update-content-command.sh
rapids-generate-scripts ${gen_rmm_args};
rapids-generate-scripts ${gen_cudf_args};
rapids-generate-scripts ${gen_raft_args};
rapids-generate-scripts ${gen_cumlprims_mg_args};
rapids-generate-scripts ${gen_cuml_args};
rapids-generate-scripts ${gen_cugraph_ops_args};
rapids-generate-scripts ${gen_cugraph_args};
rapids-generate-scripts ${gen_cuspatial_args};
EOF

find /opt/rapids \
    \( -type d -exec chmod 0775 {} \; \
    -o -type f -exec chmod 0755 {} \; \);

# Copy in bash completions
cp -ar ./etc/bash_completion.d/* /etc/bash_completion.d/;

# Clean up
# rm -rf /tmp/*;
rm -rf /var/tmp/*;
rm -rf /var/cache/apt/*;
rm -rf /var/lib/apt/lists/*;
