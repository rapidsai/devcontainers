#! /usr/bin/env bash

for cmd in $(find /opt -type f -name on-create-command.sh ! -wholename $(realpath -m "${BASH_SOURCE[0]}")); do
    . $cmd;
done
