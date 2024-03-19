#!/usr/bin/env bash

set -e;

test -f "${1}/pyproject.toml";
test "True" = "$(python -c "import toml; from packaging.requirements import Requirement; print(any(Requirement(require).name == 'scikit-build' for require in toml.load('${1}/pyproject.toml')['build-system']['requires']))" 2>/dev/null)"
