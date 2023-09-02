#! /usr/bin/env bash

if test -n "${PYTHON_PACKAGE_MANAGER:-}"; then
    if [ "${PYTHON_PACKAGE_MANAGER:-}" = "pip" ] \
    && devcontainer-utils-vault-s3-creds-test 2>&1 >/dev/null \
    && ! grep -q 'pypi.k8s.rapids.ai' <<< "$(pip config get global.extra-index-url 2>&1)"; then
        echo "Logging into the RAPIDS nightly PyPI index at 'https://pypi.k8s.rapids.ai' ...";
        echo "  This index isn't particularly secret, but we don't make it publicly accessible.";
        echo "  If you're seeing this message, you are a member of NVIDIA's GitHub organization.";
        echo "  Search for 'pypi.k8s.rapids.ai' in #swrapids-pip-packages to find the credentials.";
        read -rp "Username: " rapids_pypi_username <$(tty);
        if test -n "${rapids_pypi_username:-}"; then
            read -rsp "Password: " rapids_pypi_password <$(tty);
            if test -n "${rapids_pypi_password:-}"; then
                pip config set \
                    "global.extra-index-url" \
                    "https://${rapids_pypi_username}:${rapids_pypi_password}@pypi.k8s.rapids.ai/simple";
            else
                echo "Canceled." >&2;
            fi
            unset rapids_pypi_password;
        else
            echo "Canceled." >&2;
        fi
        unset rapids_pypi_username;
    fi

    rapids-make-${PYTHON_PACKAGE_MANAGER}-env || true;
fi
