#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-configure-sccache-dist [OPTION]...
#
# Generate and write sccache-dist configuration to `$HOME/.config/sccache/config`
#
# Boolean options:
#  -h,--help                    Print this text.
#  --no-local-compile-fallback  Disable building locally after retrying transient sccache-dist errors.
#                               (default: false)
#  --use-connection-pool        Enable sccache client HTTP connection pool.
#                               (default: false)
#
# Options that require values:
#  --auth-type (token|oauth2_code_grant_pkce|oauth2_implicit)   Auth type for build cluster auth.
#                                                               Disables client auth if omitted (not recommended).
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

_configure_sccache_dist() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'sccache configure-sccache-dist';

    auth_type="${auth_type-}";
    max_retries="${max_retries:-${SCCACHE_DIST_MAX_RETRIES-}}";
    scheduler_url="${scheduler_url:-${SCCACHE_DIST_SCHEDULER_URL-}}";
    connect_timeout="${connect_timeout:-${SCCACHE_DIST_CONNECT_TIMEOUT-}}";
    request_timeout="${request_timeout:-${SCCACHE_DIST_REQUEST_TIMEOUT-}}";

    local connection_pool="${SCCACHE_DIST_CONNECTION_POOL-}";

    if test -n "${use_connection_pool:+x}"; then
        connection_pool="true";
    fi

    local fallback_to_local_compile="${SCCACHE_DIST_FALLBACK_TO_LOCAL_COMPILE-}";

    if test -n "${no_local_compile_fallback:+x}"; then
        fallback_to_local_compile="false";
    fi

    local sccache_conf="${SCCACHE_CONF:-"$HOME/.config/sccache/config"}";

    mkdir -p "$(dirname "$sccache_conf")";
    touch "$sccache_conf";

    # Remove the values we're about to set. Deletes toml ranges like this:
    #   [dist]
    #   max_retries = 0
    #   fallback_to_local_compile = true
    #   scheduler_url = "foo.bar.xyz.com"
    #
    #   [dist.net]
    #   connection_pool = true
    #   connect_timeout = 10
    #   request_timeout = 600
    #
    #   [dist.auth]
    #   type = "foo"
    #   token = "bar"
    sed -Ei '/^\[dist.*\]/,/^(\s|\[)*$/d' "${sccache_conf}";

    # Write our new values
    if ! grep -qE "^$" <<< "${scheduler_url}"; then
        cat <<< "[dist]" >> "${sccache_conf}";
        cat <<< "scheduler_url = \"${scheduler_url}\"" >> "${sccache_conf}";
        if ! grep -qE "^$" <<< "${max_retries}"; then
            cat <<< "max_retries = ${max_retries}" >> "${sccache_conf}";
        fi
        if ! grep -qE "^$" <<< "${fallback_to_local_compile}"; then
            cat <<< "fallback_to_local_compile = ${fallback_to_local_compile}" >> "${sccache_conf}";
        fi

        cat <<< "[dist.net]" >> "${sccache_conf}";
        if ! grep -qE "^$" <<< "${connection_pool}"; then
            cat <<< "connection_pool = ${connection_pool}" >> "${sccache_conf}";
        fi
        if ! grep -qE "^$" <<< "${connect_timeout}"; then
            cat <<< "connect_timeout = "${connect_timeout}"" >> "${sccache_conf}";
        fi
        if ! grep -qE "^$" <<< "${request_timeout}"; then
            cat <<< "request_timeout = "${request_timeout}"" >> "${sccache_conf}";
        fi

        if test "${auth_type}" = token; then
            if ! grep -qE "^$" <<< "${auth_token-}"; then
                cat <<< "[dist.auth]" >> "${sccache_conf}";
                cat <<< "type = \"${auth_type}\"" >> "${sccache_conf}";
                cat <<< "token = \"${auth_token}\"" >> "${sccache_conf}";
            fi
        elif test "${auth_type}" = oauth2_implicit; then
            if ! grep -qE "^$" <<< "${auth_url-}" \
            && ! grep -qE "^$" <<< "${client_id-}"; then
                cat <<< "[dist.auth]" >> "${sccache_conf}";
                cat <<< "type = \"${auth_type}\"" >> "${sccache_conf}";
                cat <<< "auth_url = \"${auth_url}\"" >> "${sccache_conf}";
                cat <<< "client_id = \"${client_id}\"" >> "${sccache_conf}";
            fi
        elif test "${auth_type}" = oauth2_code_grant_pkce; then
            if ! grep -qE "^$" <<< "${auth_url-}" \
            && ! grep -qE "^$" <<< "${client_id-}" \
            && ! grep -qE "^$" <<< "${token_url-}"; then
                cat <<< "[dist.auth]" >> "${sccache_conf}";
                cat <<< "type = \"${auth_type}\"" >> "${sccache_conf}";
                cat <<< "auth_url = \"${auth_url}\"" >> "${sccache_conf}";
                cat <<< "client_id = \"${client_id}\"" >> "${sccache_conf}";
                cat <<< "token_url = \"${token_url}\"" >> "${sccache_conf}";
            fi
        fi
    fi
}

_configure_sccache_dist "$@" <&0;
