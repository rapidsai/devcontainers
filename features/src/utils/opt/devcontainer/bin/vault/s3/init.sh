#! /usr/bin/env bash

set -euo pipefail;

# Attempt to retrieve temporary AWS credentials from a vault
# instance using GitHub OAuth.

if [[ -z "${VAULT_HOST:-}" ]]; then
    exit 0;
fi

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

# Generate temporary AWS creds
# todo: This should work but isn't
# -d "{\"ttl\": \"43200s\"}"          \
aws_creds="$(                               \
    curl -s                                 \
        -X POST                             \
        -H "X-Vault-Token: $vault_token"    \
        -H "Content-Type: application/json" \
        "$VAULT_HOST/v1/aws/sts/devs"       \
  | jq -r '.data'                           \
)";

unset vault_token;

aws_role_arn="$(echo "$aws_creds" | jq -r '.arn')";
aws_access_key_id="$(echo "$aws_creds" | jq -r '.access_key')";
aws_session_token="$(echo "$aws_creds" | jq -r '.security_token')";
aws_secret_access_key="$(echo "$aws_creds" | jq -r '.secret_key')";

unset aws_creds;

if [[ "${aws_role_arn:-null}" == null ]]; then
    echo "Failed to generate temporary AWS S3 credentials. Exiting." >&2;
    exit 1;
fi;
if [[ "${aws_access_key_id:-null}" == null ]]; then
    echo "Failed to generate temporary AWS S3 credentials. Exiting." >&2;
    exit 1;
fi;
if [[ "${aws_session_token:-null}" == null ]]; then
    echo "Failed to generate temporary AWS S3 credentials. Exiting." >&2;
    exit 1;
fi;
if [[ "${aws_secret_access_key:-null}" == null ]]; then
    echo "Failed to generate temporary AWS S3 credentials. Exiting." >&2;
    exit 1;
fi;

# Generate AWS config files
mkdir -p ~/.aws;
cat <<EOF > ~/.aws/config
[default]
region=${SCCACHE_REGION:-us-east-2}
bucket=${SCCACHE_BUCKET:-rapids-sccache-devs}
role_arn=$aws_role_arn
EOF
cat <<EOF > ~/.aws/credentials
[default]
aws_access_key_id=$aws_access_key_id
aws_secret_access_key=$aws_secret_access_key
aws_session_token=$aws_session_token
EOF

unset aws_role_arn;
unset aws_access_key_id;
unset aws_session_token;
unset aws_secret_access_key;

chmod 0600 ~/.aws/{config,credentials};

if [ -z "${SCCACHE_S3_USE_SSL:-}" ] || \
   [ ! grep -q -E "^SCCACHE_S3_USE_SSL=${SCCACHE_S3_USE_SSL:-true}$" ~/.bashrc ]; then
    echo "export SCCACHE_S3_USE_SSL=${SCCACHE_S3_USE_SSL:-true}" >> ~/.bashrc;
fi
if [ -z "${SCCACHE_REGION:-}" ] || \
   [ ! grep -q -E "^SCCACHE_REGION=${SCCACHE_REGION:-us-east-2}$" ~/.bashrc ]; then
    echo "export SCCACHE_REGION=${SCCACHE_REGION:-us-east-2}" >> ~/.bashrc;
fi
if [ -z "${SCCACHE_BUCKET:-}" ] || \
   [ ! grep -q -E "^SCCACHE_BUCKET=${SCCACHE_BUCKET:-rapids-sccache-devs}$" ~/.bashrc ]; then
    echo "export SCCACHE_BUCKET=${SCCACHE_BUCKET:-rapids-sccache-devs}" >> ~/.bashrc;
fi

# If we succeeded at least once, install user crontab and refresh creds every 55 minutes
if ! crontab -l &> /dev/null; then
    crontab /opt/devcontainer/cron/vault-s3-init            \
 && sudo touch /var/log/vault-s3-init.log                   \
 && sudo chown $(id -u):$(id -g) /var/log/vault-s3-init.log \
 && sudo cron;
fi

echo "Successfully generated temporary AWS S3 credentials!";
