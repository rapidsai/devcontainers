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
#  --use-connection-pool        Enable sccache client HTTP connection pool.
#                               (default: false)
#
# Options that require values:
#  --auth-type (token|oauth2_code_grant_pkce|oauth2_implicit)   Auth type for build cluster auth.
#                                                               (default: token)
#  --auth-token <token>                                         Token used to authenticate with the build cluster when `--auth-type=token`.
#  --client-id <id>                                             Client ID used to authenticate with the build cluster when `--auth-type=(oauth2_code_grant_pkce|oauth2_implicit)`.
#  --auth-url <url>                                             Auth URL used to authenticate with the build cluster when `--auth-type=(oauth2_code_grant_pkce|oauth2_implicit)`.
#  --token-url <url>                                            Token URL used to authenticate with the build cluster when `--auth-type=oauth2_code_grant_pkce`.
#  --connect-timeout <num>                                      The sccache client HTTP connection timeout.
#                                                               (default: 30)
#  --request-timeout <num>                                      The sccache client HTTP request timeout.
#                                                               (default: 1800)
#  --scheduler-url <url>                                        URL of the sccache-dist build cluster.
#  --max-retries <count>                                        Maximum number of times to retry transient sccache-dist errors.
#                                                               Pass `--max-retries inf` to retry infinitely.
#                                                               Combining `--max-retries inf` with `--no-local-compile-fallback`
#                                                               ensures the sccache client relies exclusively on the build cluster.
#                                                               (default: 0)

_init_sccache_dist() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" --take '-e,--enable-sccache-dist --enable-with-github-auth' "$@" <<< "")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'sccache init-sccache-dist';

    if test -n "${enable_sccache_dist:+x}"; then
        # Add sccache-dist configuration to ~/.config/sccache/config
        devcontainer-utils-configure-sccache-dist "${OPTS[@]}" - <&0;
    elif test -n "${enable_with_github_auth:+x}"; then
        devcontainer-utils-configure-sccache-dist - <<< "       \
            --auth-type 'token' --auth-token '$(gh auth token)'";
    else
        # Delete sccache-dist configuration from ~/.config/sccache/config
        SCCACHE_DIST_MAX_RETRIES=                \
        SCCACHE_DIST_SCHEDULER_URL=              \
        SCCACHE_DIST_CONNECT_TIMEOUT=            \
        SCCACHE_DIST_REQUEST_TIMEOUT=            \
        SCCACHE_DIST_CONNECTION_POOL=            \
        SCCACHE_DIST_FALLBACK_TO_LOCAL_COMPILE=  \
        devcontainer-utils-configure-sccache-dist;
    fi

    # Restart the sccache client with the new configuration
    devcontainer-utils-start-sccache;

    # Verify sccache-dist status and configuration
    if sccache --dist-status 2>/dev/null | jq -er '.SchedulerStatus? != null' >/dev/null 2>&1; then
        devcontainer-utils-sccache-dist-status -c 17 -f tsv;
    fi
}

_init_sccache_dist "$@" <&0;
