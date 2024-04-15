#!/usr/bin/env bash

# Usage:
#  rapids-select-cmake-install-args [OPTION]...
#
# Filter an arguments list to the subset accepted by `cmake --install`.
#
# CMake Install Options:
# Boolean options:
#  --strip                                       Strip before installing.
#  -v,--verbose                                  Enable verbose output.
#
# Options that require values:
#  --config <cfg>                                For multi-configuration tools, choose <cfg>.
#  --component <comp>                            Component-based install. Only install <comp>.
#  --default-directory-permissions <permission>  Default install permission. Use default permission <permission>.
#  --prefix <prefix>                             The installation prefix CMAKE_INSTALL_PREFIX.

# shellcheck disable=SC1091
. rapids-generate-docstring;

_filter_args "$@" <&0;
