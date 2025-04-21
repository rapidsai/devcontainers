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
#  --connection-pool            Enable sccache client HTTP connection pool.
#                               (default: false)
#  --keepalive                  Enable sccache client HTTP keepalive.
#
# Options that require values:
#  --auth-type (token|oauth2_code_grant_pkce|oauth2_implicit)   Auth type for build cluster auth.
#                                                               Disables client auth if omitted (not recommended).
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

_configure_sccache_dist() {
    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'sccache configure-sccache-dist';

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
    #   connect_timeout = 5
    #   request_timeout = 600
    #
    #   [dist.net.keepalive]
    #   enabled = true
    #   interval = 20
    #   timeout = 60
    #
    #   [dist.auth]
    #   type = "foo"
    #   token = "bar"

    while grep -qE "^\[dist.*\]" "${sccache_conf}"; do
        sed -Ei '/^\[dist.*\]/,/^(\s|\[)*$/d' "${sccache_conf}";
    done

    printf "%s\n" "$(< "${sccache_conf}")" > "${sccache_conf}.new"
    mv "${sccache_conf}"{.new,};

    scheduler_url="${scheduler_url:-${SCCACHE_DIST_URL-}}";

    # Write our new values
    if test -n "${scheduler_url:+x}"; then
        cat <<< "" >> "${sccache_conf}";
        cat <<< "[dist]" >> "${sccache_conf}";
        cat <<< "scheduler_url = \"${scheduler_url}\"" >> "${sccache_conf}";
        if test -n "${max_retries:+x}"; then
            cat <<< "max_retries = ${max_retries}" >> "${sccache_conf}";
        fi
        if test -n "${no_local_compile_fallback:+x}"; then
            cat <<< "fallback_to_local_compile = false" >> "${sccache_conf}";
        fi

        if test -n "${connection_pool:+x}" \
        || test -n "${connect_timeout:+x}" \
        || test -n "${request_timeout:+x}"; then
            cat <<< "" >> "${sccache_conf}";
            cat <<< "[dist.net]" >> "${sccache_conf}";
            if test -n "${connection_pool:+x}"; then
                cat <<< "connection_pool = true" >> "${sccache_conf}";
            fi
            if test -n "${connect_timeout:+x}"; then
                cat <<< "connect_timeout = "${connect_timeout}"" >> "${sccache_conf}";
            fi
            if test -n "${request_timeout:+x}"; then
                cat <<< "request_timeout = "${request_timeout}"" >> "${sccache_conf}";
            fi
        fi

        if test -n "${keepalive:+x}"; then
            cat <<< "" >> "${sccache_conf}";
            cat <<< "[dist.net.keepalive]" >> "${sccache_conf}";
            cat <<< "enabled = true" >> "${sccache_conf}";
            if test -n "${keepalive_interval:+x}"; then
                cat <<< "interval = "${keepalive_interval}"" >> "${sccache_conf}";
            fi
            if test -n "${keepalive_timeout:+x}"; then
                cat <<< "timeout = "${keepalive_timeout}"" >> "${sccache_conf}";
            fi
        fi

        case "${auth_type:-}" in
            token)
                if test -n "${auth_token:+x}"; then
                    cat <<< "" >> "${sccache_conf}";
                    cat <<< "[dist.auth]" >> "${sccache_conf}";
                    cat <<< "type = \"${auth_type}\"" >> "${sccache_conf}";
                    cat <<< "token = \"${auth_token}\"" >> "${sccache_conf}";
                fi
                ;;
            oauth2_implicit)
                if test -n "${auth_url:+x}" \
                && test -n "${client_id:+x}"; then
                    cat <<< "" >> "${sccache_conf}";
                    cat <<< "[dist.auth]" >> "${sccache_conf}";
                    cat <<< "type = \"${auth_type}\"" >> "${sccache_conf}";
                    cat <<< "auth_url = \"${auth_url}\"" >> "${sccache_conf}";
                    cat <<< "client_id = \"${client_id}\"" >> "${sccache_conf}";
                fi
                ;;
            oauth2_code_grant_pkce)
                if test -n "${auth_url:+x}" \
                && test -n "${client_id:+x}" \
                && test -n "${token_url:+x}"; then
                    cat <<< "" >> "${sccache_conf}";
                    cat <<< "[dist.auth]" >> "${sccache_conf}";
                    cat <<< "type = \"${auth_type}\"" >> "${sccache_conf}";
                    cat <<< "auth_url = \"${auth_url}\"" >> "${sccache_conf}";
                    cat <<< "client_id = \"${client_id}\"" >> "${sccache_conf}";
                    cat <<< "token_url = \"${token_url}\"" >> "${sccache_conf}";
                fi
                ;;
            *)
                ;;
        esac
    fi
}

_configure_sccache_dist "$@" <&0;
