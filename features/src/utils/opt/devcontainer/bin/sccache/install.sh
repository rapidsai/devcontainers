#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-install-sccache [OPTION]...
#
# Install a specific sccache client binary from GitHub releases.
#
# Boolean options:
#  -h,--help       Print this text.
#
# Options that require values:
# --repo <repo>   The GitHub repository to use.
#                 (default: ${SCCACHE_REPOSITORY:-mozilla/sccache})
# --version <ver> The sccache version to install (e.g. `0.10.0`).
#                 (default: ${SCCACHE_VERSION:-latest})
#

# shellcheck disable=SC1091
. "$(dirname "$(realpath -m "${BASH_SOURCE[0]}")")/find-version-from-git-tags.sh";

_install_sccache() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'sccache install-sccache';

    while pgrep sccache >/dev/null 2>&1; do
        devcontainer-utils-stop-sccache --kill-all;
    done

    local sccache_version="${version:-"${SCCACHE_VERSION:-"latest"}"}";
    local github_repo="${repo:-"${SCCACHE_REPOSITORY:-"mozilla/sccache"}"}";

    local find_version_args=("https://github.com/$github_repo");
    if test "$sccache_version" = rapids; then
        sccache_version=latest;
        find_version_args+=("tags/v" "." "-rapids.*" "true");
    fi

    _find_version_from_git_tags sccache_version "${find_version_args[@]}";

    while test -n "${sccache_version:+x}" && \
        ! wget --no-hsts -q -O- "https://github.com/$github_repo/releases/download/v$sccache_version/sccache-v$sccache_version-$(uname -m)-unknown-linux-musl.tar.gz" \
        | sudo tar -C /usr/bin -zf - --wildcards --strip-components=1 -x '*/sccache' 2>/dev/null \
       && sudo chmod +x /usr/bin/sccache; do
        echo "(!) failed to download sccache v${sccache_version}. Attempting to fall back one version to retry...";
        _find_version_from_git_tags sccache_version "${find_version_args[@]}" "${sccache_version}";
    done

    if test -n "${sccache_version:+x}"; then
        echo "Installed sccache v$(sccache --version | cut -d' ' -f2) to $(which sccache)";
    else
        echo "(!) failed to download sccache" >&2;
        return 1
    fi
}

_install_sccache "$@" <&0;
