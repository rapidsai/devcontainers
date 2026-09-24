#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check_cuda_minor_matrix_selector() (
    set -euo pipefail

    test_dir="$(mktemp -d)"
    trap 'rm -rf "${test_dir}"' EXIT
    mkdir -p "${test_dir}/bin" "${test_dir}/home/fixture"
    touch "${test_dir}/home/fixture/dependencies.yaml"

    cat > "${test_dir}/bin/rapids-generate-docstring" <<'EOF'
_parse_args() {
    printf '%s\n' 'exclude=()' 'include=()' 'matrix_entry=()' 'key=()' 'OPTS=()'
}
EOF

    : > "${test_dir}/bin/devcontainer-utils-debug-output"

    cat > "${test_dir}/bin/rapids-list-repos" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' 'repos_length=1' 'repos_0_name=fixture' 'repos_0_path=fixture'
EOF

    cat > "${test_dir}/bin/rapids-dependency-file-generator" <<'EOF'
#!/usr/bin/env bash
while (($#)); do
    if [[ "$1" == "--matrix" ]]; then
        printf '%s\n' "$2" > "${MATRIX_SELECTOR_FILE}"
        exit 0
    fi
    shift
done
exit 1
EOF

    chmod +x "${test_dir}/bin/rapids-list-repos" "${test_dir}/bin/rapids-dependency-file-generator"

    MATRIX_SELECTOR_FILE="${test_dir}/matrix-selector" \
    HOME="${test_dir}/home" \
    CUDA_VERSION=99.99.0 \
    PATH="${test_dir}/bin:${PATH}" \
        rapids-make-conda-dependencies > /dev/null

    if ! grep -Eq '(^|;)cuda=99\.99(;|$)' "${test_dir}/matrix-selector"; then
        printf 'Expected cuda=99.99, got: %s\n' "$(cat "${test_dir}/matrix-selector")" >&2
        return 1
    fi
)

check "Conda dependencies use the full CUDA minor version" check_cuda_minor_matrix_selector

# Report result
reportResults
