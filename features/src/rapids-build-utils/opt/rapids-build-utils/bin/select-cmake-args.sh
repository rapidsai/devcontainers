#!/usr/bin/env bash

# Usage:
#  rapids-select-cmake-args [OPTION]...
#
# Filter an arguments list to the subset that we pass to CMake.
#
# CMake Options:
#  -h,--help                       Print usage information and exit.
#  -S <path>                       Explicitly specify a source directory.
#  -B <path>                       Explicitly specify a build directory.
#  -D <var>[:<type>]=<value>       Create or update a cmake cache entry.
#  -G <generator-name>             Specify a build system generator.
#  -T <toolset-name>               Specify toolset name if supported by generator.
#  -A <platform-name>              Specify platform name if supported by generator.
#  --toolchain <file>              Specify toolchain file [CMAKE_TOOLCHAIN_FILE].
#  --install-prefix <directory>    Specify install directory [CMAKE_INSTALL_PREFIX].
#  -W (dev)                        Enable developer warnings.
#  -W (no-dev)                     Suppress developer warnings.
#  -W (deprecated)                 Enable deprecation warnings.
#  -W (no-deprecated)              Suppress deprecation warnings.
#  -W (error=dev)                  Make developer warnings errors.
#  -W (no-error=dev)               Make developer warnings not errors.
#  -W (error=deprecated)           Make deprecated macro and function warnings errors.
#  -W (no-error=deprecated)        Make deprecated macro and function warnings not errors.
#  --preset <preset>               Specify a configure preset.
#  --fresh                         Configure a fresh build tree, removing any existing cache file.
#  --graphviz <file>               Generate graphviz of dependencies, see CMakeGraphVizOptions.cmake for more.
#  --log-level,--loglevel (ERROR|WARNING|NOTICE|STATUS|VERBOSE|DEBUG|TRACE)
#                                  Set the verbosity of messages from CMake files.
#                                  --loglevel is also accepted for backward compatibility reasons.
#  --log-context                   Prepend log messages with context, if given
#  --debug-trycompile              Do not delete the try_compile build tree. Only useful on one try_compile at a time.
#  --debug-output                  Put cmake in a debug mode.
#  --debug-find                    Put cmake find in a debug mode.
#  --debug-find-pkg <pkg-name>     Limit cmake debug-find to the comma-separated list of packages
#  --debug-find-var <var-name>     Limit cmake debug-find to the comma-separated list of result variables
#  --trace                         Put cmake in trace mode.
#  --trace-expand                  Put cmake in trace mode with variable expansion.
#  --trace-format (human|json-v1)  Set the output format of the trace.
#  --trace-source <file>           Trace only this CMake file/module.  Multiple options allowed.
#  --trace-redirect <file>         Redirect trace output to a file instead of stderr.
#  --warn-uninitialized            Warn about uninitialized values.
#  --no-warn-unused-cli            Don't warn about command line options.
#  --check-system-vars             Find problems with variable usage in system files.
#  --compile-no-warning-as-error   Ignore COMPILE_WARNING_AS_ERROR property and CMAKE_COMPILE_WARNING_AS_ERROR variable.
#
#  --profiling-format <fmt>        Output data for profiling CMake scripts. Supported formats: google-trace
#  --profiling-output <file>       Select an output path for the profiling data enabled through --profiling-format.

# shellcheck disable=SC1091
. rapids-generate-docstring;

_filter_args "$@" <&0;
