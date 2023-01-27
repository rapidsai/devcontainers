#! /usr/bin/env bash

set -euo pipefail;

vault_token=null;

VAULT_HOST="$1";
client_nonce=$RANDOM;
auth_url="$(\
    curl -s -X POST -d "\
    {\
        \"role\": \"devs\",\
        \"client_nonce\": \"$client_nonce\",\
        \"redirect_uri\": \"$VAULT_HOST/ui/vault/auth/oidc/oidc/callback\"\
    }" \
    "$VAULT_HOST/v1/auth/oidc/oidc/auth_url" \
  | jq -r '.data.auth_url'
)";

if [[ "${auth_url:-null}" == null ]]; then exit 1; fi;

parse_params() {
    local query="$@";
    for p in ${query//&/ }; do
        kvp=( ${p/=/ } );
        k=${kvp[0]};
        v=${kvp[1]};
        eval "$k=$v";
    done
    echo "nonce='$nonce'; state='$state';";
}

eval "$(parse_params "$(echo "$auth_url" | cut -d'?' -f2)")";

if [[ "${nonce:-null}" == null ]]; then exit 1; fi;
if [[ "${state:-null}" == null ]]; then exit 1; fi;

echo -e "Please navigate to:\n\t$auth_url" >&2;
read -p "Enter code from URL parameters: " code </dev/tty >&2;

if [[ "${code:-null}" == null ]]; then exit 1; fi;

cb_url="$VAULT/v1/auth/oidc/oidc/callback";
cb_url+="?code=$code";
cb_url+="&state=$state";
cb_url+="&nonce=$nonce";
cb_url+="&client_nonce=$client_nonce";

vault_token="$(                \
    curl -s -X GET "$cb_url"   \
  | jq -r '.auth.client_token' \
)";

unset code;
unset state;
unset nonce;
unset client_nonce;
unset auth_url;
unset cb_url;

echo "vault_token='$vault_token'";
