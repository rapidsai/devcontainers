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
#                 (default: mozilla/sccache)
# --version <ver> The sccache version to install (e.g. `0.10.0`).
#                 (default: latest)
#


# Assign variable one scope above the caller
# Usage: local "$1" && _upvar $1 "value(s)"
# Param: $1  Variable name to assign value to
# Param: $*  Value(s) to assign.  If multiple values, an array is
#            assigned, otherwise a single value is assigned.
# See: http://fvue.nl/wiki/Bash:_Passing_variables_by_reference
_upvar() {
    if unset -v "$1"; then
        if (( $# == 2 )); then
            eval $1=\"\$2\";
        else
            eval $1=\(\"\${@:2}\"\);
        fi;
    fi
}

# Figure out correct version of a three part version number is not passed
_find_version_from_git_tags() {
    local variable_name="$1"
    local requested_version="${!variable_name}"
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository="$2"
    local prefix="${3:-"tags/v"}"
    local separator="${4:-"."}"
    local suffix="${5:-}"
    local last_part_optional="${6:-"false"}"
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local last_part=
        if [ "${last_part_optional}" = "true" ]; then
            last_part+="(${escaped_separator}[0-9]+)?"
            last_part+="(${escaped_separator}[0-9]+)?"
            if [ -n "${suffix}" ]; then
                last_part+="(${suffix})?"
            fi
        else
            last_part+="${escaped_separator}[0-9]+"
            last_part+="${escaped_separator}[0-9]+"
            if [ -n "${suffix}" ]; then
                last_part+="(${suffix})"
            fi
        fi
        local regex="${prefix}\\K[0-9]+${last_part}$"
        local remote_upstream_fetch="$(git --no-pager config get remote.upstream.fetch)";
        if test -n "${remote_upstream_fetch:+x}"; then
            git config unset --global remote.upstream.fetch
        fi
        local -r version_list="$(git ls-remote --tags "${repository}" | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if test -n "${remote_upstream_fetch:+x}"; then
            git config set --global remote.upstream.fetch "${remote_upstream_fetch}";
        fi
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            _upvar "${variable_name}" "$(head -n 1 <<< "${version_list}")"
        else
            set +e
            _upvar "${variable_name}" "$(grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)" <<< "${version_list}")"
            set -e
        fi
    fi
    if [ -z "${!variable_name}" ] || ! grep "^${!variable_name//./\\.}$" <<< "${version_list}" > /dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        return 1
    fi
}

_install_sccache() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'sccache install-sccache';

    local sccache_version="${version:-"latest"}";
    local github_repo="${repo:-"mozilla/sccache"}";

    _find_version_from_git_tags sccache_version "https://github.com/$github_repo" "" "" "-.*" "true";

    while pgrep sccache >/dev/null 2>&1; do
        devcontainer-utils-stop-sccache --kill-all;
    done

    # Install sccache
    wget --no-hsts -q -O- \
        "https://github.com/$github_repo/releases/download/v$sccache_version/sccache-v$sccache_version-$(uname -m)-unknown-linux-musl.tar.gz" \
  | sudo tar -C /usr/bin -zf - --wildcards --strip-components=1 -x '*/sccache' \
 && sudo chmod +x /usr/bin/sccache;

    echo "Installed sccache v$(sccache --version | cut -d' ' -f2) to $(which sccache)"
}

_install_sccache "$@" <&0;
