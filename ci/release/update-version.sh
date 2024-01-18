#!/bin/bash
# Copyright (c) 2024, NVIDIA CORPORATION.

## Usage
# bash update-version.sh <new_version>

set -euo pipefail

# Format is YY.MM.PP - no leading 'v' or trailing 'a'
NEXT_FULL_TAG=$1

# Get current version
CURRENT_TAG=$(git tag --merged HEAD | grep -xE '^v.*' | sort --version-sort | tail -n 1 | tr -d 'v')
CURRENT_MAJOR=$(echo $CURRENT_TAG | awk '{split($0, a, "."); print a[1]}')
CURRENT_MINOR=$(echo $CURRENT_TAG | awk '{split($0, a, "."); print a[2]}')
CURRENT_PATCH=$(echo $CURRENT_TAG | awk '{split($0, a, "."); print a[3]}')
CURRENT_SHORT_TAG=${CURRENT_MAJOR}.${CURRENT_MINOR}

#Get <major>.<minor> for next version
NEXT_MAJOR=$(echo $NEXT_FULL_TAG | awk '{split($0, a, "."); print a[1]}')
NEXT_MINOR=$(echo $NEXT_FULL_TAG | awk '{split($0, a, "."); print a[2]}')
NEXT_PATCH=$(echo $NEXT_FULL_TAG | awk '{split($0, a, "."); print a[3]}')
NEXT_SHORT_TAG=${NEXT_MAJOR}.${NEXT_MINOR}
NEXT_FULL_TAG=${NEXT_MAJOR}.${NEXT_MINOR}.${NEXT_PATCH}
NEXT_UCX_PY_VERSION="$(curl -sL https://version.gpuci.io/rapids/${NEXT_SHORT_TAG}).*"

# Need to distutils-normalize the versions for some use cases
CURRENT_SHORT_TAG_PEP440=$(python -c "from setuptools.extern import packaging; print(packaging.version.Version('${CURRENT_SHORT_TAG}'))")
NEXT_SHORT_TAG_PEP440=$(python -c "from setuptools.extern import packaging; print(packaging.version.Version('${NEXT_SHORT_TAG}'))")
NEXT_FULL_TAG_PEP440=$(python -c "from setuptools.extern import packaging; print(packaging.version.Version('${NEXT_FULL_TAG}'))")
PATCH_PEP440=$(python -c "from setuptools.extern import packaging; print(packaging.version.Version('${NEXT_PATCH}'))")
echo "current is ${CURRENT_SHORT_TAG_PEP440}, next is ${NEXT_SHORT_TAG_PEP440}"

echo "Preparing release $CURRENT_TAG => $NEXT_FULL_TAG"

# Inplace sed replace; workaround for Linux and Mac
function sed_runner() {
    sed -i.bak ''"$1"'' $2 && rm -f ${2}.bak
}

sed_runner "s/devcontainers:.*-cpp/devcontainers:${NEXT_SHORT_TAG}-cpp/g" USAGE.md
sed_runner "s|features/\([[:alnum:]]\+\):[[:digit:]]\+\.[[:digit:]]\+\"|features/\1:${NEXT_SHORT_TAG}\"|g" USAGE.md

for file in $(find .devcontainer -name devcontainer.json); do
  sed_runner "s|rapidsai/devcontainers:.*-cpp|rapidsai/devcontainers:${NEXT_SHORT_TAG}-cpp|g" "$file"
done

for file in $(find . -name manifest.yaml); do
  sed_runner "s/branch-.*/branch-${NEXT_SHORT_TAG}/g" "$file"
done

for file in $(find features -name devcontainer-feature.json); do
  tmp=$(mktemp)
  jq --arg ver "$NEXT_FULL_TAG_PEP440" '.version = $ver' "$file" > "$tmp" && mv "$tmp" "$file"
done
