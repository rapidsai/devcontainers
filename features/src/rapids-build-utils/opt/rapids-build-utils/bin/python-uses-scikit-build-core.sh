#!/usr/bin/env bash

set -e;

test -f "${1}/pyproject.toml";
test "scikit_build_core.build" = "$(/usr/bin/python3 -c "import toml; print(toml.load('${1}/pyproject.toml')['build-system']['build-backend'])" 2>/dev/null)";
