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

_install_sccache() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'sccache install-sccache';

    while pgrep sccache >/dev/null 2>&1; do
        devcontainer-utils-stop-sccache --kill-all;
    done

    local attempts;
    local sccache_bin_dir;
    local old_sccache_version;
    local new_sccache_version="${version:-"${SCCACHE_VERSION:-"latest"}"}";
    local github_repo="${repo:-"${SCCACHE_REPOSITORY:-"mozilla/sccache"}"}";

    if test "$new_sccache_version" = rapids; then
        new_sccache_version="latest";
        github_repo="rapidsai/sccache";
    fi

    sccache_bin_dir="$(dirname "$(which sccache 2>/dev/null || echo "/usr/bin/sccache")")";
    old_sccache_version="$(sccache --version 2>/dev/null | cut -d' ' -f2 || echo "sccache not installed")";

    attempts=0
    while test "${new_sccache_version:-latest}" = latest; do
        new_sccache_version="$(gh api repos/${github_repo}/releases/latest --jq '.tag_name | sub("^v"; "")')";
        if test -n "${new_sccache_version:+x}"; then
            break;
        elif test "$((attempts++))" -lt 10; then
            echo "(!) Failed to load latest ${github_repo} version. Retrying (${attempts}/10)..." >&2;
            new_sccache_version="latest"
            sleep 10;
        else
            echo "(!) Failed to load latest ${github_repo} version after 10 attempts." >&2;
            return 1;
        fi
    done

    attempts=0;
    if test -n "${old_sccache_version##"${new_sccache_version}"}"; then
        # Install sccache to "$sccache_bin_dir"
        echo "Downloading sccache v${new_sccache_version}..." >&2
        while ! gh release download "v${new_sccache_version}" -R "${github_repo}" -p "sccache-v${new_sccache_version}-$(uname -m)-unknown-linux-musl.tar.gz" -O- \
              | sudo tar -C "$sccache_bin_dir" -zf - --overwrite --wildcards --strip-components=1 -x '*/sccache'; do
            if test "$((attempts++))" -lt 10; then
                echo "(!) Failed to download sccache v${new_sccache_version}. Retrying (${attempts}/10)..." >&2;
                sleep 10;
            else
                echo "(!) Failed to download sccache v${new_sccache_version} after 10 attempts." >&2;
                return 1;
            fi
        done
        # Verify installation
        echo "Installed $(sccache --version) to $(which sccache)" >&2
    else
        echo "sccache v${new_sccache_version} is already installed, skipping" >&2
    fi
}

_install_sccache "$@" <&0;
