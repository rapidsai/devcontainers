#!/usr/bin/env bash

# Usage:
#  rapids-get-num-archs-jobs-and-load [OPTION]...
#
# Compute an appropriate total number of jobs, load, and CUDA archs to build in parallel.
# This routine scales the input `-j` with respect to the `-a` and `-m` values, taking into account the
# amount of available system memory (free mem + swap), in order to balance the job and arch parallelism.
#
# note: This wouldn't be necessary if `nvcc` interacted with the POSIX jobserver.
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
#  --max-total-system-memory <num>        An upper-bound on the amount of total system memory (in GiB) to use during
#                                         C++ and CUDA device compilations.
#                                         Smaller values yield fewer parallel C++ and CUDA device compilations.
#                                         (default: all available memory)
#  --max-device-obj-memory-usage <num>    An upper-bound on the amount of memory each CUDA device object compilation
#                                         is expected to take. This is used to estimate the number of parallel device
#                                         object compilations that can be launched without hitting the system memory
#                                         limit.
#                                         Higher values yield fewer parallel CUDA device object compilations.
#                                         (default: 1)

# shellcheck disable=SC1091
. rapids-generate-docstring;

get_num_archs_jobs_and_load() {
    local -;
    set -euo pipefail

    eval "$(_parse_args "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'get-num-archs-jobs-and-load';

    # The return value of nproc is (who knew!) constrained by the
    # values of OMP_NUM_THREADS and/or OMP_THREAD_LIMIT
    # Since we want the physical number of processors here, pass --all
    local -r n_cpus="$(nproc --all)";

    if test ${#j[@]} -gt 0 && test -z "${j:-}"; then
        j="${n_cpus}";
    fi

    parallel="${j:-${JOBS:-${PARALLEL_LEVEL:-1}}}";
    max_archs="${max_archs:-${MAX_DEVICE_OBJ_TO_COMPILE_IN_PARALLEL:-${arch:-}}}";
    max_device_obj_memory_usage="${max_device_obj_memory_usage:-${MAX_DEVICE_OBJ_MEMORY_USAGE:-1}}";

    local n_arch="${archs:-1}";

    # currently: 60-real;70-real;75-real;80-real;86-real;90
    # see: https://github.com/rapidsai/rapids-cmake/blob/branch-24.04/rapids-cmake/cuda/set_architectures.cmake#L54
    local n_arch_rapids=6;

    if test -z "${archs:-}" \
    && test -n "${INFER_NUM_DEVICE_ARCHITECTURES:-}"; then
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

    max_archs="${max_archs:-${MAX_DEVICE_OBJ_TO_COMPILE_IN_PARALLEL:-${n_arch}}}";

    # Clamp to `min(n_arch, max_archs)` threads per job
    n_arch=$((n_arch > max_archs ? max_archs : n_arch));

    local mem_for_device_objs="$((n_arch * max_device_obj_memory_usage))";

    local -r free_mem="$(free --gibi | grep -E '^Mem:' | tr -s '[:space:]' | cut -d' ' -f7 || echo '0')";
    local -r freeswap="$(free --gibi | grep -E '^Swap:' | tr -s '[:space:]' | cut -d' ' -f4 || echo '0')";
    local -r mem_total="${max_total_system_memory:-${MAX_TOTAL_SYSTEM_MEMORY:-$((free_mem + freeswap))}}";
    local n_load=$((parallel > n_cpus ? n_cpus : parallel));
    # shellcheck disable=SC2155
    local n_jobs="$(
        echo "
scale=0
max_cpu=(${n_load} / ${n_arch} / 2 * 3)
max_mem=(${mem_total} / ${mem_for_device_objs})
if(max_cpu < max_mem) max_cpu else max_mem
" | bc
    )"
    n_jobs=$((n_jobs < 1 ? 1 : n_jobs));
    n_jobs=$((n_arch > 1 ? n_jobs : n_load));

    echo "declare n_arch=${n_arch}";
    echo "declare n_jobs=${n_jobs}";
    echo "declare n_load=${n_load}";
}

get_num_archs_jobs_and_load "$@" <&0;
