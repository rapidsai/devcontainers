#! /usr/bin/env bash

if test -n "${PYTHON_PACKAGE_MANAGER:-}"; then
    if [ "${PYTHON_PACKAGE_MANAGER:-}" = "pip" ] \
    && devcontainer-utils-vault-s3-creds-test 2>&1 >/dev/null \
    && ! grep -q 'pypi.anaconda.org' <<< "$(pip config get global.extra-index-url 2>&1)"; then
        pip config set \
            "global.extra-index-url" \
            "https://pypi.anaconda.org/rapidsai-wheels-nightly/simple";
    fi

    rapids-make-${PYTHON_PACKAGE_MANAGER}-env || true;
fi
