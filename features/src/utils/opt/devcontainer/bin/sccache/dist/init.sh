#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-init-sccache-dist [OPTION]...
#
# Generate and write sccache-dist configuration to `$HOME/.config/sccache/config`,
# then restart sccache to ensure the configuration is applied.
#
# Boolean options:
#  -h,--help                    Print this text.
#  -e,--enable-sccache-dist     Enable sccache-dist. If omitted, disable sccache-dist.
#                               (default: false)
#  --enable-with-github-auth    Enable sccache-dist and configure it to use GitHub token auth.
#                               Shorthand for `-e --auth-type token --auth-token $(gh auth token)`
#                               (default: false)
#  --no-local-compile-fallback  Disable building locally after retrying transient sccache-dist errors.
#                               (default: false)
#  --connection-pool            Enable sccache client HTTP connection pool.
#                               (default: false)
#  --keepalive                  Enable sccache client HTTP keepalive.
#
# Options that require values:
#  --auth-type (token|oauth2_code_grant_pkce|oauth2_implicit)   Auth type for build cluster auth.
#                                                               (default: token)
#  --auth-token <token>                                         Token used to authenticate with the build cluster when `--auth-type=token`.
#  --client-id <id>                                             Client ID used to authenticate with the build cluster when `--auth-type=(oauth2_code_grant_pkce|oauth2_implicit)`.
#  --auth-url <url>                                             Auth URL used to authenticate with the build cluster when `--auth-type=(oauth2_code_grant_pkce|oauth2_implicit)`.
#  --token-url <url>                                            Token URL used to authenticate with the build cluster when `--auth-type=oauth2_code_grant_pkce`.
#  --connect-timeout <num>                                      The sccache client HTTP connection timeout.
#                                                               (default: 5)
#  --request-timeout <num>                                      The sccache client HTTP request timeout.
#                                                               (default: 600)
#  --keepalive-interval <num>                                   The sccache HTTP keepalive interval
#                                                               (default: 20)
#  --keepalive-timeout <num>                                    The sccache HTTP keepalive timeout
#                                                               (default: 60)
#  --scheduler-url <url>                                        URL of the sccache-dist build cluster.
#  --max-retries <count>                                        Maximum number of times to retry transient sccache-dist errors.
#                                                               Pass `--max-retries inf` to retry infinitely.
#                                                               Combining `--max-retries inf` with `--no-local-compile-fallback`
#                                                               ensures the sccache client relies exclusively on the build cluster.
#                                                               (default: 0)

_init_sccache_dist() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" --take '-e,--enable-sccache-dist --enable-with-github-auth' "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'sccache init-sccache-dist';

    while true; do
        if test -n "${enable_sccache_dist:+x}"; then
            # Passthrough args to configure-sccache-dist
            devcontainer-utils-configure-sccache-dist - <<< "${OPTS[*]@Q}";
            break;
        fi
        if test -n "${enable_with_github_auth:+x}"; then
            if devcontainer-utils-shell-is-interactive; then
                # Initialize the GitHub CLI with the appropriate user scopes
                # shellcheck disable=SC1091
                . devcontainer-utils-init-github-cli;
            fi
            read -ra sccache_dist_gh_scopes <<< "${SCCACHE_DIST_GH_SCOPES:-"read:enterprise"}";
            read -ra sccache_dist_gh_scopes <<< "${sccache_dist_gh_scopes[*]/#/--scopes }";
            if grep -qE "^$" <(devcontainer-utils-github-user-scopes "${sccache_dist_gh_scopes[@]}" --complement); then
                devcontainer-utils-configure-sccache-dist - <<< "--auth-type token --auth-token '$(gh auth token)' ${OPTS[*]@Q}";
                break;
            fi
        fi
        # Reset sccache-dist configuration
        SCCACHE_DIST_URL= devcontainer-utils-configure-sccache-dist;
        break;
    done

    # Restart the sccache client with the new configuration
    devcontainer-utils-start-sccache;

    # Verify sccache-dist status and configuration
    if sccache --dist-status 2>/dev/null | jq -er '.SchedulerStatus? != null' >/dev/null 2>&1; then
        devcontainer-utils-sccache-dist-status -c 17 -f tsv;
    fi
}

_init_sccache_dist "$@" <&0;
