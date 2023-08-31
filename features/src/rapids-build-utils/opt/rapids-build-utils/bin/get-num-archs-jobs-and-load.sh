#! /usr/bin/env bash

get_num_archs_jobs_and_load() {
    set -euo pipefail

    local archs="";
    local parallel="";
    local max_device_obj_memory_usage="";

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            a|archs                           |
            j|parallel                        |
            m|max-device-obj-memory-usage     |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    archs="${a:-${archs:-}}";
    archs="${archs//"true"/}";
    parallel="${j:-${parallel:-}}";
    parallel="${parallel//"true"/}";

    max_device_obj_memory_usage="${m:-${max_device_obj_memory_usage:-${MAX_DEVICE_OBJ_MEMORY_USAGE:-}}}";
    max_device_obj_memory_usage="${max_device_obj_memory_usage//"true"/}";
    max_device_obj_memory_usage="${max_device_obj_memory_usage:-1}";

    local n_arch=${archs:-1};

    if test -z "${archs:-}"; then
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
    local all_cpus="${parallel:-${JOBS:-${PARALLEL_LEVEL:-$(nproc)}}}";
    local n_jobs="$(cat<<____EOF | bc
scale=0
max_cpu=(${all_cpus} / ${n_arch} / 2 * 3)
max_mem=((${free_mem} + ${freeswap}) / ${n_arch} / ${max_device_obj_memory_usage})
if(max_cpu < max_mem) max_cpu else max_mem
____EOF
    )";
    n_jobs=$((n_jobs < 1 ? 1 : n_jobs));
    local n_load="${all_cpus}";

    echo "n_arch=${n_arch}";
    echo "n_jobs=${n_jobs}";
    echo "n_load=${n_load}";
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(get_num_archs_jobs_and_load "$@");
