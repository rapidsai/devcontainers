#! /usr/bin/env bash

# Find the parent dir of the `setup.py` files in a RAPIDS library source tree.
python_pkg_roots() {
    set -euo pipefail;

    cd ~;
    find "$@"                                          \
        -type f                                        \
     \( -name 'setup.py' -or -name 'pyproject.toml' \) \
      ! -path '*conda*'                                \
      ! -path '*build*'                                \
        -exec sh -c "                                  \
            grep -HP 'name(\s+)?=(\s+)?f?' {}          \
          | head -n1" \;                               \
      2>/dev/null                                      \
      | sed -r 's@/(setup.py|pyproject.toml):.*$@@g'   \
    ;
}

(python_pkg_roots "$@");
