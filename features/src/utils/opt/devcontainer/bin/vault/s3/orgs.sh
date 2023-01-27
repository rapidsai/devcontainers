#! /usr/bin/env bash

set -euo pipefail;

get_user_orgs() {

    local VAULT_HOST="$1";
    local allowed_orgs="${VAULT_GITHUB_ORGS:-nvidia nv-legate rapids}";
    local allowed_orgs="${allowed_orgs// /|}";

    local user_orgs="$(                              \
        gh api                                       \
            user/orgs                                \
            --jq '.[].login'                         \
            -H "Accept: application/vnd.github+json" \
      | grep --color=never -E "($allowed_orgs)"      \
    )";

    echo "user_orgs='$user_orgs'";
    echo "allowed_orgs='$allowed_orgs'";
}

get_user_orgs "$@"
