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
#  -h,--help,--usage            print this text
#
# Options that require values:
#  -a,--archs <num>                       Build <num> CUDA archs in parallel
#                                         (default: 1)
#  -j,--parallel <num>                    Run <num> parallel compilation jobs
#  -m,--max-device-obj-memory-usage <num> An upper-bound on the amount of memory each CUDA device object compilation
#                                         is expected to take. This is used to estimate the number of parallel device
#                                         object compilations that can be launched without hitting the system memory
#                                         limit.
#                                         Higher values yield fewer parallel CUDA device object compilations.
#                                         (default: 1)

. devcontainer-utils-parse-args-from-docstring;

get_num_archs_jobs_and_load() {
    set -Eeuo pipefail

    parse_args_or_show_help - <<< "$@";

    local archs="${a:-${archs:-1}}";
    archs="${archs//"true"/}";

    local parallel="${j:-${parallel:-${JOBS:-${PARALLEL_LEVEL:-1}}}}";
    parallel="${parallel//"true"/}";
    parallel="${parallel:-$(nproc)}";

    local max_device_obj_memory_usage="${m:-${max_device_obj_memory_usage:-${MAX_DEVICE_OBJ_MEMORY_USAGE:-}}}";
    max_device_obj_memory_usage="${max_device_obj_memory_usage//"true"/}";
    max_device_obj_memory_usage="${max_device_obj_memory_usage:-1}";

    local n_arch=${archs:-1};

    if test -z "${archs:-}" \
    && test -n "${INFER_NUM_DEVICE_ARCHITECTURES:-}"; then
        archs=$(rapids-parse-cmake-var-from-args CMAKE_CUDA_ARCHITECTURES "${__rest__[@]}");
        archs="${archs:-${CMAKE_CUDA_ARCHITECTURES:-${CUDAARCHS:-}}}";

        case "${archs:-}" in
            native | NATIVE)
                # should technically be the number of unique GPU archs
                # in the system, but this should be good enough for most
                n_arch=1;
                ;;
            all | all-major)
                # Max out at 3 threads per object
                n_arch=3;
                ;;
            ALL | RAPIDS)
                # currently: 60-real;70-real;75-real;80-real;86-real;90
                # see: https://github.com/rapidsai/rapids-cmake/blob/branch-23.10/rapids-cmake/cuda/set_architectures.cmake#L54
                n_arch=6;
                ;;
            *)
                # Otherwise if explicitly defined, count the number of archs in the list
                n_arch="$(echo "${archs}" | grep -o ';' | wc -l)";
                n_arch="$(((n_arch + 1) / 2))";
                ;;
        esac
    fi

    # Clamp between 1 and 3 threads per nvcc job
    n_arch=$(( n_arch < 1 ? 1 : n_arch > 3 ? 3 : n_arch ));

    local free_mem=$(free --giga | grep -E '^Mem:' | tr -s '[:space:]' | cut -d' ' -f7 || echo '0');
    local freeswap=$(free --giga | grep -E '^Swap:' | tr -s '[:space:]' | cut -d' ' -f4 || echo '0');
    local all_cpus="${parallel}";
    local n_load="${all_cpus}";
    local n_jobs="$(cat<<____EOF | bc
scale=0
max_cpu=(${all_cpus} / ${n_arch} / 2 * 3)
max_mem=((${free_mem} + ${freeswap}) / ${n_arch} / ${max_device_obj_memory_usage})
if(max_cpu < max_mem) max_cpu else max_mem
____EOF
    )";
    n_jobs=$((n_jobs < 1 ? 1 : n_jobs));
    n_jobs=$((n_arch > 1 ? n_jobs : n_load));

    echo "n_arch=${n_arch}";
    echo "n_jobs=${n_jobs}";
    echo "n_load=${n_load}";
}

if test -n "${rapids_build_utils_debug:-}" \
&& ( test -z "${rapids_build_utils_debug##*"all"*}" \
  || test -z "${rapids_build_utils_debug##*"get-num-archs-jobs-and-load"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(get_num_archs_jobs_and_load "$@");
