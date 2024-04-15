#!/usr/bin/env bash

# Usage:
#  rapids-select-pip-wheel-args [OPTION]...
#
# Filter an arguments list to the subset that `pip wheel` accepts.
#
# @_include_pip_wheel_options;
# @_include_pip_package_index_options;
# @_include_pip_general_options;

# shellcheck disable=SC1091
. rapids-generate-docstring;

_filter_args "$@" <&0;
