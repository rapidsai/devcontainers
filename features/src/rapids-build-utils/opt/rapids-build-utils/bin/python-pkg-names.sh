#! /usr/bin/env -S bash -euo pipefail

# Read the `name="<pkg>"` fields from any `setup.py` files in a RAPIDS library
# source tree. This seems to be the most reliable way to determine the actual
# list of possible package names we should exclude from the combined conda env
python_pkg_names() {
    cd ~;
    # the regex will continue until morale improves
    rapids-python-pkg-roots "$@"             \
      | xargs -I{} echo '{}/setup.py'        \
      | xargs -I{} grep -E 'name=f?' {}      \
      | sed -r "s/^.*?name=f?('|\")//"       \
      | sed -r "s/('|\").*$//"               \
      | sed -r 's/\{.*$//'                   \
      ;
}

python_pkg_names "$@";
