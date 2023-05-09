#! /usr/bin/env bash

devcontainer-utils-init-git;

# Refresh the S3 creds if they don't exist, are expired, or are <= 4 hours from expiring
if ! devcontainer-utils-vault-s3-test 2>&1 >/dev/null;
then devcontainer-utils-vault-s3-init;
else devcontainer-utils-vault-s3-export 0;
fi

. /etc/profile.d/*-devcontainer-utils.sh;
