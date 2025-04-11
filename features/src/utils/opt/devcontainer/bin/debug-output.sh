#! /usr/bin/env bash

{ set +x; } 2>/dev/null;

for var in ${1}; do
    var="${!var:-}";
    if test -n "${var:+x}"; then
        for str in '*' ${2}; do
            if test -z "${var##*"${str}"*}"; then
                __xtrace=1;
                break;
            fi
        done
        unset str;
    fi
    shift;
done
shift;
unset var;

if test -n "${__xtrace:+x}"; then
    unset __xtrace;
    PS4="+ ${BASH_SOURCE[${#BASH_SOURCE[@]}-1]}:\${LINENO} ";
    set -x;
fi
