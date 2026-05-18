#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2025, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
#################################
# devcontainers Version Updater #
#################################

## Usage
# Primary interface:   bash update-version.sh <new_version> [--run-context=main|release]
# Fallback interface:  [RAPIDS_RUN_CONTEXT=main|release] bash update-version.sh <new_version>
# CLI arguments take precedence over environment variables
# Defaults to main when no run-context is specified

set -euo pipefail

# Parse command line arguments
CLI_RUN_CONTEXT=""
VERSION_ARG=""

for arg in "$@"; do
    case $arg in
        --run-context=*)
            CLI_RUN_CONTEXT="${arg#*=}"
            shift
            ;;
        *)
            if [[ -z "$VERSION_ARG" ]]; then
                VERSION_ARG="$arg"
            fi
            ;;
    esac
done

# Format is YY.MM.PP - no leading 'v' or trailing 'a'
NEXT_FULL_TAG="$VERSION_ARG"

# Determine RUN_CONTEXT with CLI precedence over environment variable, defaulting to main
if [[ -n "$CLI_RUN_CONTEXT" ]]; then
    RUN_CONTEXT="$CLI_RUN_CONTEXT"
    echo "Using run-context from CLI: $RUN_CONTEXT"
elif [[ -n "${RAPIDS_RUN_CONTEXT:-}" ]]; then
    RUN_CONTEXT="$RAPIDS_RUN_CONTEXT"
    echo "Using run-context from environment: $RUN_CONTEXT"
else
    RUN_CONTEXT="main"
    echo "No run-context provided, defaulting to: $RUN_CONTEXT"
fi

# Validate RUN_CONTEXT value
if [[ "${RUN_CONTEXT}" != "main" && "${RUN_CONTEXT}" != "release" ]]; then
    echo "Error: Invalid run-context value '${RUN_CONTEXT}'"
    echo "Valid values: main, release"
    exit 1
fi

# Validate version argument
if [[ -z "$NEXT_FULL_TAG" ]]; then
    echo "Error: Version argument is required"
    echo "Usage: $0 <new_version> [--run-context=<context>]"
    echo "   or: [RAPIDS_RUN_CONTEXT=<context>] $0 <new_version>"
    echo "Note: Defaults to main when run-context is not specified"
    exit 1
fi

# Get current version
CURRENT_TAG=$(git tag --merged HEAD | grep -xE '^v.*' | sort --version-sort | tail -n 1 | tr -d 'v')
CURRENT_MAJOR=$(echo "$CURRENT_TAG" | awk '{split($0, a, "."); print a[1]}')
CURRENT_MINOR=$(echo "$CURRENT_TAG" | awk '{split($0, a, "."); print a[2]}')
CURRENT_SHORT_TAG=${CURRENT_MAJOR}.${CURRENT_MINOR}

# Get <major>.<minor> for next version
NEXT_MAJOR=$(echo "$NEXT_FULL_TAG" | awk '{split($0, a, "."); print a[1]}')
NEXT_MINOR=$(echo "$NEXT_FULL_TAG" | awk '{split($0, a, "."); print a[2]}')
NEXT_PATCH=$(echo "$NEXT_FULL_TAG" | awk '{split($0, a, "."); print a[3]}')
NEXT_SHORT_TAG=${NEXT_MAJOR}.${NEXT_MINOR}
NEXT_FULL_TAG=${NEXT_MAJOR}.${NEXT_MINOR}.${NEXT_PATCH}

# Need to distutils-normalize the versions for some use cases
NEXT_SHORT_TAG_PEP440=$(python -c "from packaging.version import Version; print(Version('${NEXT_SHORT_TAG}'))")
NEXT_FULL_TAG_PEP440=$(python -c "from packaging.version import Version; print(Version('${NEXT_FULL_TAG}'))")

# Log update context
if [[ "${RUN_CONTEXT}" == "main" ]]; then
    echo "Preparing development branch update $CURRENT_TAG => $NEXT_FULL_TAG (targeting main branch)"
elif [[ "${RUN_CONTEXT}" == "release" ]]; then
    echo "Preparing release branch update $CURRENT_TAG => $NEXT_FULL_TAG (targeting release/${NEXT_SHORT_TAG} branch)"
fi

# Centralized version file update
echo "${NEXT_FULL_TAG}" > VERSION

# Inplace sed replace; workaround for Linux and Mac
function sed_runner() {
    sed -i.bak ''"$1"'' "$2" && rm -f "${2}".bak
}

sed_runner "s/devcontainers:.*-cpp/devcontainers:${NEXT_SHORT_TAG}-cpp/g" USAGE.md
sed_runner "s|features/\([[:alnum:]]\+\):[[:digit:]]\+\.[[:digit:]]\+\"|features/\1:${NEXT_SHORT_TAG_PEP440}\"|g" USAGE.md

for file in $(find .devcontainer -name devcontainer.json); do
  sed_runner "s|rapidsai/devcontainers:.*-cpp|rapidsai/devcontainers:${NEXT_SHORT_TAG}-cpp|g" "$file"
  sed_runner "s@rapids-\${localWorkspaceFolderBasename}-[0-9.]*@rapids-\${localWorkspaceFolderBasename}-${NEXT_SHORT_TAG}@g" "${file}"
done

for file in $(find features -name devcontainer-feature.json); do
  tmp=$(mktemp)
  jq --arg ver "$NEXT_FULL_TAG_PEP440" '.version = $ver' "$file" > "$tmp" && mv "$tmp" "$file"
done
