#! /usr/bin/env -S bash -euo pipefail

# Read the `name="<pkg>"` fields from any `setup.py` files in a RAPIDS library
# source tree. This seems to be the most reliable way to determine the actual
# list of possible package names we should exclude from the combined conda env
python_pkg_names() {
    cd ~;
    # the regex will continue until morale improves
    for dir in $(rapids-python-pkg-roots "$@"); do
        local name="";
        if [[ -z "${name}" && -f "${dir}/setup.py" ]]; then
            name="$(                              \
                grep -E 'name=f?' ${dir}/setup.py \
              | sed -r "s/^.*?name=f?('|\")//"    \
              | sed -r "s/('|\").*$//"            \
              | sed -r 's/\{.*$//'                \
             || echo ''                           \
            )";
        fi
        if [[ -z "${name}" && -f "${dir}/pyproject.toml" ]]; then
            name="$(python -c "\
import toml;\
print(toml.load('${dir}/pyproject.toml')['project']['name'])")";
        fi
        if [[ -n "${name}" ]]; then
            echo "${name}";
        fi
    done
}

python_pkg_names "$@";
