#! /usr/bin/env bash

jobs_and_archs() {
    set -euo pipefail

    local parallel="";

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            j|parallel                        |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    parallel="${j:-${parallel:-}}";
    if [ "${parallel:-}" = "true" ]; then parallel=""; fi

    local archs;
    archs=$(rapids-parse-cmake-var-from-args CMAKE_CUDA_ARCHITECTURES "${__rest__[@]}");
    archs="${archs:-${CMAKE_CUDA_ARCHITECTURES:-${CUDAARCHS:-}}}";

    local n_arch=1;

    case "${archs:-}" in
        native | NATIVE)
            # should technically be the number of unique GPU archs
            # in the system, but this should be good enough for most
            n_arch=1;
            ;;
        all | all-major)
            # Max out at 6 threads per object
            n_arch=6;
            ;;
        ALL | RAPIDS)
            # currently: 60-real;70-real;75-real;80-real;86-real;90
            # see: https://github.com/rapidsai/rapids-cmake/blob/branch-23.10/rapids-cmake/cuda/set_architectures.cmake#L54
            n_arch=6;
            # n_arch=$((6 / 2));
            ;;
        *)
            # Otherwise if explicitly defined, count the number of archs in the list
            n_arch="$(echo "${archs}" | grep -o ';' | wc -l)";
            n_arch="$(((n_arch + 1) / 2))";
            ;;
    esac

    # Clamp between 1 and 6 threads per nvcc job
    n_arch=$(( n_arch < 1 ? 1 : n_arch > 6 ? 6 : n_arch ));

    local free_mem=$(free --giga | head -n2 | tail -n1 | cut -d ':' -f2 | tr -s '[:space:]' | cut -d' ' -f7);
    local all_cpus="${parallel:-${JOBS:-${PARALLEL_LEVEL:-$(nproc)}}}";
    local n_jobs=$((
        (all_cpus / n_arch) < (free_mem / n_arch / 5) ?
        (all_cpus / n_arch) : (free_mem / n_arch / 5)
    ));
    local n_load="${all_cpus}";

    echo "n_arch=${n_arch}";
    echo "n_jobs=${n_jobs}";
    echo "n_load=${n_load}";
}

if test -n "${rapids_build_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

(jobs_and_archs "$@");
