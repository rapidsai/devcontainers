#!/bin/bash

set -e

source dev-container-features-test-lib

test_root="$(mktemp -d)"
trap 'rm -rf "${test_root}"' EXIT

mkdir -p "${test_root}/bin" "${test_root}/home/test-repo"

cat > "${test_root}/bin/devcontainer-utils-parse-args" <<'EOF'
#!/bin/bash

_print_usage() {
    :
}

_parse_args_for_file() {
    shift

    local -a parsed_keys=()
    while test "$#" -gt 0; do
        case "$1" in
            --skip|--take)
                shift 2
                ;;
            -k|--key)
                parsed_keys+=("$2")
                shift 2
                ;;
            -m|--manifest)
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    cat <<'DECLARATIONS'
declare -a OPTS=()
declare -a exclude=()
declare -a include=()
declare -a key=()
declare -a matrix_entry=()
declare -a requirement=()
DECLARATIONS

    local parsed_key
    for parsed_key in "${parsed_keys[@]}"; do
        printf 'key+=(%q)\n' "${parsed_key}"
    done
}
EOF
chmod +x "${test_root}/bin/devcontainer-utils-parse-args"

cat > "${test_root}/bin/devcontainer-utils-debug-output" <<'EOF'
#!/bin/bash
:
EOF
chmod +x "${test_root}/bin/devcontainer-utils-debug-output"

cat > "${test_root}/bin/rapids-list-repos" <<'EOF'
#!/bin/bash
cat <<'REPOS'
declare repos_length=1
declare repos_0_name=dfg-atomic
declare repos_0_path=test-repo
REPOS
EOF
chmod +x "${test_root}/bin/rapids-list-repos"

cat > "${test_root}/bin/rapids-python-pkg-names" <<'EOF'
#!/bin/bash
:
EOF
chmod +x "${test_root}/bin/rapids-python-pkg-names"

cat > "${test_root}/bin/rapids-python-conda-pkg-names" <<'EOF'
#!/bin/bash
:
EOF
chmod +x "${test_root}/bin/rapids-python-conda-pkg-names"

cat > "${test_root}/bin/rapids-dependency-file-generator" <<'EOF'
#!/bin/bash

set -euo pipefail

file_key=
output=

while test "$#" -gt 0; do
    case "$1" in
        --file-key)
            file_key="$2"
            shift 2
            ;;
        --output)
            output="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

printf '%s\n' "${file_key}" >> "${DFG_CALL_LOG}"

if test "${file_key}" == hard_error; then
    echo partial-output-must-not-escape
    echo 'mock hard generation failure' 1>&2
    exit 42
fi

case "${output}" in
    requirements)
        cat <<'REQUIREMENTS'
# generated
dfg-atomic-success
REQUIREMENTS
        ;;
    conda)
        cat <<'CONDA'
# generated
name: dfg-atomic
channels:
  - conda-forge
dependencies:
  - dfg-atomic-success
CONDA
        ;;
    *)
        echo "unexpected output type: ${output}" 1>&2
        exit 2
        ;;
esac
EOF
chmod +x "${test_root}/bin/rapids-dependency-file-generator"

cat > "${test_root}/manifest.yaml" <<'EOF'
repos:
  - name: dfg-atomic
    path: test-repo
EOF

cat > "${test_root}/home/test-repo/dependencies.yaml" <<'EOF'
files:
  success: {}
  hard_error: {}
EOF

dependencies_skip_missing_key() {
    local command="$1"
    local label="$2"
    local stdout="${test_root}/${label}-missing.stdout"
    local stderr="${test_root}/${label}-missing.stderr"
    local calls="${test_root}/${label}-missing.calls"

    : > "${calls}"
    if ! env \
        PATH="${test_root}/bin:${PATH}" \
        HOME="${test_root}/home" \
        DFG_CALL_LOG="${calls}" \
        "${command}" \
            --manifest "${test_root}/manifest.yaml" \
            --key success \
            --key missing \
            --key success \
            > "${stdout}" 2> "${stderr}"; then
        return 1
    fi

    test -s "${stdout}" \
        && grep -Fq dfg-atomic-success "${stdout}" \
        && test "$(wc -l < "${calls}")" -eq 1 \
        && grep -Fxq success "${calls}" \
        && ! grep -Fxq missing "${calls}"
}

dependencies_fail_atomically() {
    local command="$1"
    local label="$2"
    local stdout="${test_root}/${label}-failure.stdout"
    local stderr="${test_root}/${label}-failure.stderr"
    local calls="${test_root}/${label}-failure.calls"

    : > "${calls}"
    if env \
        PATH="${test_root}/bin:${PATH}" \
        HOME="${test_root}/home" \
        DFG_CALL_LOG="${calls}" \
        "${command}" \
            --manifest "${test_root}/manifest.yaml" \
            --key success \
            --key hard_error \
            > "${stdout}" 2> "${stderr}"; then
        return 1
    fi

    test ! -s "${stdout}" \
        && grep -Fq 'mock hard generation failure' "${stderr}" \
        && test "$(wc -l < "${calls}")" -eq 2 \
        && grep -Fxq success "${calls}" \
        && grep -Fxq hard_error "${calls}"
}

check "pip dependencies skip missing keys" dependencies_skip_missing_key rapids-make-pip-dependencies pip
check "pip dependency failures are atomic" dependencies_fail_atomically rapids-make-pip-dependencies pip
check "conda dependencies skip missing keys" dependencies_skip_missing_key rapids-make-conda-dependencies conda
check "conda dependency failures are atomic" dependencies_fail_atomically rapids-make-conda-dependencies conda

reportResults
