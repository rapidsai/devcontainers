#! /usr/bin/env bash

# Read the `name="<pkg>"` fields from any `setup.py` files in a RAPIDS library
# source tree. This seems to be the most reliable way to determine the actual
# list of possible package names we should exclude from the combined conda env
python_conda_pkg_names() {
    set -euo pipefail;

    cd ~;
    # the regex will continue until morale improves
    find "$@"                         \
      -type f -name 'meta.yaml'       \
      ! -path '*/.conda/*'            \
      ! -path '*/build/*'             \
      ! -path '*/_skbuild/*'          \
        -exec grep -E 'name: ?' {} \; \
      2>/dev/null                     \
      | tr -d '[:blank:]'             \
      | cut -d':' -f2                 \
    ;
}

(python_conda_pkg_names "$@");
