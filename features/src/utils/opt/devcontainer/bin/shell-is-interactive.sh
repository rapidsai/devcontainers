#! /usr/bin/env bash

if (exec < /dev/tty) && [ "${CODESPACES:-false}" != "true" ]; then
    exit 0;
fi

exit 1;
