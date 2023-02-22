#! /usr/bin/env bash

set -euo pipefail;

# Attempt to retrieve temporary AWS credentials from a vault
# instance using GitHub OAuth.

if [[ -z "${VAULT_HOST:-}" ]]; then exit 0; fi
if [[ -z "${SCCACHE_BUCKET:-}" ]]; then exit 0; fi

# Initialize the GitHub CLI with the appropriate user scopes
. /opt/devcontainer/bin/github/cli/init.sh;

# Check whether the user is in one of the allowed GitHub orgs
eval "$(/opt/devcontainer/bin/vault/s3/orgs.sh "$VAULT_HOST")";

if [[ -z "${user_orgs:-}" ]]; then
    exit 0;
fi

# Remove existing credentials in case vault declines to issue new ones.
rm -rf ~/.aws/{config,credentials};

echo ""
echo "Attempting to use your GitHub account to authenticate";
echo "with vault at '$VAULT_HOST'.";
echo ""

vault_token=null;

# Attempt to authenticate with GitHub
eval "$(/opt/devcontainer/bin/vault/auth/github.sh "$VAULT_HOST" ${user_orgs})";

if [[ "${vault_token:-null}" == null ]]; then
    echo "Your GitHub user was not recognized by vault. Exiting." >&2;
    exit 1;
fi

echo "Successfully authenticated with vault!";

ttl="${VAULT_S3_TTL:-"43200s"}";
uri="${VAULT_S3_URI:-"v1/aws/creds/devs"}";

# Generate temporary AWS creds
aws_creds="$(                               \
    curl -s                                 \
        -X GET                              \
        -H "X-Vault-Token: $vault_token"    \
        -H "Content-Type: application/json" \
        "$VAULT_HOST/$uri?ttl=$ttl"         \
  | jq -r '.data'                           \
)";

unset vault_token;

aws_access_key_id="$(echo "$aws_creds" | jq -r '.access_key')";
aws_secret_access_key="$(echo "$aws_creds" | jq -r '.secret_key')";

unset aws_creds;

if [[ "${aws_access_key_id:-null}" == null ]]; then
    echo "Failed to generate temporary AWS S3 credentials. Exiting." >&2;
    exit 1;
fi;
if [[ "${aws_secret_access_key:-null}" == null ]]; then
    echo "Failed to generate temporary AWS S3 credentials. Exiting." >&2;
    exit 1;
fi;

# Generate AWS config files
mkdir -p ~/.aws;

echo "$(date '+%s')" > ~/.aws/stamp;

cat <<EOF > ~/.aws/config
[default]
${SCCACHE_REGION:+region=$SCCACHE_REGION}
${SCCACHE_BUCKET:+bucket=$SCCACHE_BUCKET}
EOF
cat <<EOF > ~/.aws/credentials
[default]
aws_access_key_id=$aws_access_key_id
aws_secret_access_key=$aws_secret_access_key
EOF

unset aws_access_key_id;
unset aws_secret_access_key;

chmod 0600 ~/.aws/{config,credentials};

. /opt/devcontainer/bin/vault/s3/export.sh

echo "Successfully generated temporary AWS S3 credentials!";
