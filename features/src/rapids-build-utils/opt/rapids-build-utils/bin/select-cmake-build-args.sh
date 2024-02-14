#!/usr/bin/env bash

# Usage:
#  rapids-select-cmake-build-args [OPTION]...
#
# Filter an arguments list to the subset accepted by `cmake --build`.
#
# CMake Build Options:
# Boolean options:
#  --clean-first                               Build target 'clean' first, then build. (To clean only, use --target 'clean'.)
#  -v,--verbose                                Enable verbose output - if supported - including the build commands to be executed.
#
# Options that require values:
#  --preset <preset>                           Specify a build preset.
#  -j,--parallel <num>                         Build in parallel using the given number of jobs.
#                                              If <num> is omitted the native build tool's default number is used.
#                                              The CMAKE_BUILD_PARALLEL_LEVEL environment variable specifies a default parallel level when this option is not given.
#  -t,--target <tgt>                           Build <tgt> instead of default targets.
#  --config <cfg>                              For multi-configuration tools, choose <cfg>.
#  --resolve-package-references (on|only|off)  Restore/resolve package references during build.

# shellcheck disable=SC1091
. rapids-generate-docstring;

_filter_args "$@" <&0;
