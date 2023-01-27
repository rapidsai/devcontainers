#! /usr/bin/env bash

for cmd in $(find /opt -type f -name post-create-command.sh ! -wholename $(realpath -m $0)); do
    . $cmd;
done
