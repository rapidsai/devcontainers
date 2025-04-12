#!/usr/bin/env bash

# Usage:
#  rapids-get-num-archs-jobs-and-load [OPTION]...
#
# Compute an appropriate total number of jobs, load, and CUDA archs to build in parallel.
#
# Boolean options:
#  -h,--help                              Print this text.
#
# Options that require values:
#  --archs <num>                          Build <num> CUDA archs in parallel.
#                                         (default: 1)
#  -j,--parallel <num>                    Run <num> parallel compilation jobs.
#  --max-archs <num>                      Build at most <num> CUDA archs in parallel.
#                                         (default: 3)

# shellcheck disable=SC1091
. rapids-generate-docstring;

get_num_archs_jobs_and_load() {
    local -;
    set -euo pipefail

    eval "$(_parse_args "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'get-num-archs-jobs-and-load';

    # nproc --all returns 2x the number of threads in Ubuntu24.04+,
    # so instead we cound the number of processors in /proc/cpuinfo
    local -r n_cpus="$(grep -cP 'processor\s+:' /proc/cpuinfo)";

    if test ${#j[@]} -gt 0 && ! test -n "${j:+x}"; then
        j="${n_cpus}";
    fi

    parallel="${j:-${JOBS:-${PARALLEL_LEVEL:-1}}}";
    max_archs="${max_archs:-${MAX_DEVICE_OBJ_TO_COMPILE_IN_PARALLEL:-${arch:-}}}";

    local n_arch="${archs:-1}";

    # currently: 70-real;75-real;80-real;86-real;90-real;100-real;120
    # see: https://github.com/rapidsai/rapids-cmake/blob/branch-25.04/rapids-cmake/cuda/set_architectures.cmake#L59
    local n_arch_rapids=7;

    if ! test -n "${archs:+x}" && test -n "${INFER_NUM_DEVICE_ARCHITECTURES:+x}"; then
        archs="$(rapids-select-cmake-define CMAKE_CUDA_ARCHITECTURES "${OPTS[@]}" || echo)";
        archs="${archs:-${CMAKE_CUDA_ARCHITECTURES:-${CUDAARCHS:-}}}";

        case "${archs:-}" in
            native | NATIVE)
                # should technically be the number of unique GPU archs
                # in the system, but this should be good enough for most
                n_arch=1;
                ;;
            all | all-major)
                # Max out at ${max_archs} threads per job
                n_arch="${max_archs:-${n_arch_rapids}}";
                ;;
            ALL | RAPIDS)
                n_arch=${n_arch_rapids};
                ;;
            *)
                # Otherwise if explicitly defined, count the number of archs in the list
                n_arch="$(tr ';' ' ' <<< "${archs} " | tr -s '[:blank:]' | grep -o ' ' | wc -l)";
                ;;
        esac
    fi

    if test "${n_arch}" -le 0; then
        n_arch=1;
    else
        max_archs="${max_archs:-${MAX_DEVICE_OBJ_TO_COMPILE_IN_PARALLEL:-${n_arch}}}";
        # Clamp to `min(n_arch, max_archs)` threads per job
        n_arch=$((n_arch > max_archs ? max_archs : n_arch));
    fi

    local n_load=$((parallel > n_cpus ? n_cpus : parallel));
    local n_jobs="$((parallel < 1 ? 1 : parallel))";

    echo "declare n_arch=${n_arch}";
    echo "declare n_jobs=${n_jobs}";
    echo "declare n_load=${n_load}";
}

get_num_archs_jobs_and_load "$@" <&0;
