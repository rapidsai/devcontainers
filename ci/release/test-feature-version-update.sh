#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026, NVIDIA CORPORATION.
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

updater="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/update-version.sh"
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

# The updater's unrelated source-version lookup is isolated from the network.
mkdir -p "$work_dir/bin" "$work_dir/repo"
printf '#!/usr/bin/env bash\nprintf "0.53\\n"\n' > "$work_dir/bin/curl"
chmod +x "$work_dir/bin/curl"
export PATH="$work_dir/bin:$PATH"
unset RAPIDS_RUN_CONTEXT
cd "$work_dir/repo"
mkdir -p .devcontainer features/src/cuda features/src/rapids-build-utils/opt/rapids-build-utils
printf '26.12.00\n' > VERSION
touch USAGE.md
printf '{"version":"26.12.3"}\n' > features/src/cuda/devcontainer-feature.json
printf '{"version":"26.12.7"}\n' > features/src/rapids-build-utils/devcontainer-feature.json
manifest=features/src/rapids-build-utils/opt/rapids-build-utils/manifest.yaml
printf 'x-git-defaults:\n  tag: main\nrepos:\n  - name: ucxx\n    git:\n      tag: main\n' > "$manifest"
git init -q
git -c user.name=Test -c user.email=test@example.com -c commit.gpgsign=false \
    commit --allow-empty -qm baseline
git -c tag.gpgSign=false tag v26.12.00a

feature_version() {
    jq -r '.version' "features/src/$1/devcontainer-feature.json"
}

# Same-series main updates preserve independent patches, even for package patches.
bash "$updater" 26.12.00 --run-context=main
test "$(feature_version cuda)" = 26.12.3
test "$(feature_version rapids-build-utils)" = 26.12.7
bash "$updater" 26.12.01 --run-context=main
test "$(feature_version cuda)" = 26.12.3
test "$(feature_version rapids-build-utils)" = 26.12.7

# Release preparation changes build-utils payload and bumps only that feature.
bash "$updater" 26.12.00 --run-context=release
test "$(feature_version cuda)" = 26.12.3
test "$(feature_version rapids-build-utils)" = 26.12.8
cp features/src/rapids-build-utils/devcontainer-feature.json "$work_dir/first.json"
cp "$manifest" "$work_dir/first.yaml"
bash "$updater" 26.12.00 --run-context=release
cmp "$work_dir/first.json" features/src/rapids-build-utils/devcontainer-feature.json
cmp "$work_dir/first.yaml" "$manifest"

# A new series initializes its own feature versions and remains idempotent.
bash "$updater" 27.02.00 --run-context=main
test "$(feature_version cuda)" = 27.2.0
test "$(feature_version rapids-build-utils)" = 27.2.0
bash "$updater" 27.02.00 --run-context=main
test "$(feature_version rapids-build-utils)" = 27.2.0
echo 'Feature version update checks passed.'
