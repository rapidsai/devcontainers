#! /usr/bin/env bash

jobs_and_archs() {
    set -euo pipefail

    local free_mem=$(free -g | head -n2 | tail -n1 | cut -d ':' -f2 | tr -s '[:space:]' | cut -d' ' -f7);
    local max_cpus=$((free_mem / 4));
    local all_cpus=$(nproc);

    local archs;
    if test ${#@} -gt 0; then
        archs=$(rapids-parse-cmake-var-from-args CMAKE_CUDA_ARCHITECTURES "$@");
    fi

    archs="${archs:-${CMAKE_CUDA_ARCHITECTURES:-${CUDAARCHS:-}}}";

    local n_jobs="${JOBS:-${PARALLEL_LEVEL:-$(( all_cpus < max_cpus ? all_cpus : max_cpus ))}}";
    local n_archs=1;

    case "${archs:-}" in
        native | NATIVE)
            # should technically be the number of unique GPU archs
            # in the system, but this should be good enough for most
            n_archs=1;
            ;;
        all | all-major)
            # Max out at 6 threads
            n_archs=6;
            ;;
        ALL | RAPIDS)
            # currently: 60-real;70-real;75-real;80-real;86-real;90
            # see: https://github.com/rapidsai/rapids-cmake/blob/branch-23.08/rapids-cmake/cuda/set_architectures.cmake#L54
            n_archs=6;
            ;;
        *)
            # Otherwise if explicitly defined, count the number of archs in the list
            n_archs="$(echo "${archs}" | grep -o ';' | wc -l)";
            n_archs="$((n_archs + 1))";
            ;;
    esac

    # Clamp between 1 and 6 threads per nvcc job
    n_archs=$(( n_archs < 1 ? 1 : n_archs > 6 ? 6 : n_archs ));

    n_jobs=$((n_jobs / 2 * 3 / n_archs + 1));

    echo "n_jobs=${n_jobs}";
    echo "n_arch=${n_archs}";
}

(jobs_and_archs "$@");
