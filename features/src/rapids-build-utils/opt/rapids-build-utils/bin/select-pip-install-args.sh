#!/usr/bin/env bash

# Usage:
#  rapids-select-pip-install-args [OPTION]...
#
# Filter an arguments list to the subset that `pip install` accepts.
#
# @_include_pip_install_options;
# @_include_pip_package_index_options;
# @_include_pip_general_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

_filter_args "$@" <&0;
