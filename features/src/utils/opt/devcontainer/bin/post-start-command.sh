#! /usr/bin/env bash

for cmd in $(find /opt -type f -name post-start-command.sh ! -wholename $(realpath -m $0)); do
    . $cmd;
done
