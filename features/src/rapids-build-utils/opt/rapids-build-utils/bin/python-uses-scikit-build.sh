#!/usr/bin/env bash

set -e;

test -f "${1}/pyproject.toml";
test "True" = "$(/usr/local/python/current/bin/python -c "import toml; print(any('scikit-build-core' not in x and 'scikit-build' in x for x in toml.load('${1}/pyproject.toml')['build-system']['requires']))")";
