#! /usr/bin/env bash

find ~/ -maxdepth 1 -exec bash -c '\
[ $(stat --format "%U:%G" "{}") != "$(id -u):$(id -g)" ] \
&& sudo chown -R $(id -u):$(id -g) {}' \;

. devcontainer-utils-init-git;
. devcontainer-utils-vault-s3-init;
