#! /usr/bin/env -S bash -euo pipefail

# Find the parent dir of the `setup.py` files in a RAPIDS library source tree.
python_pkg_roots() {
    cd ~;
    find "$@"                          \
        -type f                        \
        -name 'setup.py'               \
      ! -path '*conda*'                \
      ! -path '*build*'                \
        -exec grep -HE 'name=f?' {} \; \
      | sed -r 's@/setup.py:.*$@@g'    \
    ;
}

python_pkg_roots "$@";
