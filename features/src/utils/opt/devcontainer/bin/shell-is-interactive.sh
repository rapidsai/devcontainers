#! /usr/bin/env bash

# PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;

if (exec < /dev/tty) && [ "${CODESPACES:-false}" != "true" ]; then
    exit 0;
fi

exit 1;
