#!/usr/bin/env bash

set -e;

test -f "${1}/pyproject.toml";

# where rapids-build-backend is used, its does a bit of work then forwards on to another build backend... which might be scikit-build-core
[[ "scikit_build_core.build" == "$(/usr/bin/python3 -c "import toml; print(toml.load('${1}/pyproject.toml')['build-system']['build-backend'])" 2>/dev/null)" ]]                 \
||                                                                                                                                                                              \
[[ "scikit_build_core.build" == "$(/usr/bin/python3 -c "import toml; print(toml.load('${1}/pyproject.toml')['tool']['rapids-build-backend']['build-backend'])" 2>/dev/null)" ]] \
;
