#! /usr/bin/env bash

jobs_and_archs() {
    set -euo pipefail

    local free_mem=$(free -g | head -n2 | tail -n1 | cut -d ':' -f2 | tr -s '[:space:]' | cut -d' ' -f7);
    local max_cpus=$((free_mem / 4));
    local all_cpus=${JOBS:-${PARALLEL_LEVEL:-$(nproc --ignore=2)}};
    local n_jobs=$(( all_cpus < max_cpus ? all_cpus : max_cpus ));

    local archs;
    archs=$(rapids-parse-cmake-var-from-args CMAKE_CUDA_ARCHITECTURES "$@");
    archs="${archs:-${CMAKE_CUDA_ARCHITECTURES:-${CUDAARCHS:-}}}";

    local n_archs=1;

    case "${archs:-}" in
        native | NATIVE)
            # should technically be the number of unique GPU archs
            # in the system, but this should be good enough for most
            n_archs=1;
            ;;
        all | all-major)
            # Max out at 4 threads per object
            n_archs=4;
            ;;
        ALL | RAPIDS)
            # currently: 60-real;70-real;75-real;80-real;86-real;90
            # see: https://github.com/rapidsai/rapids-cmake/blob/branch-23.10/rapids-cmake/cuda/set_architectures.cmake#L54
            n_archs=$((6 / 2));
            ;;
        *)
            # Otherwise if explicitly defined, count the number of archs in the list
            n_archs="$(echo "${archs}" | grep -o ';' | wc -l)";
            n_archs="$(((n_archs + 1) / 2))";
            ;;
    esac

    # Clamp between 1 and 4 threads per nvcc job
    n_archs=$(( n_archs < 1 ? 1 : n_archs > 4 ? 4 : n_archs ));

    echo "n_jobs=$(( n_jobs < n_archs ? 1 : (n_jobs / 2 * 3 / n_archs) ))";
    echo "n_arch=${n_archs}";
}

(jobs_and_archs "$@");
