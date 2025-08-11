#! /usr/bin/env bash

if tty >/dev/null 2>&1 && (exec </dev/tty) && ! "${CODESPACES:-false}" && ! test -n "${CI:+x}"; then
    exit 0;
fi

exit 1;
