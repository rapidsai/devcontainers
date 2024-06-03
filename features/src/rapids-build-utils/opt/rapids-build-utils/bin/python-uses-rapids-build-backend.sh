#!/usr/bin/env bash

set -e;

test -f "${1}/pyproject.toml";
test "rapids_build_backend.build" = "$(/usr/bin/python3 -c "import toml; print(toml.load('${1}/pyproject.toml')['build-system']['build-backend'])" 2>/dev/null)";
