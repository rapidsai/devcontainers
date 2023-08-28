#! /usr/bin/env bash

build_rapids() {
    set -euo pipefail;

    local output="";

    eval "$(                                  \
        devcontainer-utils-parse-args --names "
            o|output
            "                                 \
            - <<< "$@"                        \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    maybe_write_build_log() {
        if test -z "${output:-}"; then
            cat -;
        else
            cat - | tee ~/"${1}/${1}-build.log";
        fi
    }

    sccache -z;

    (
        echo "building RMM";
        clean-rmm;
        build-rmm -DBUILD_BENCHMARKS=ON;
        sccache -s;
    ) 2>&1 | maybe_write_build_log rmm;

    (
        echo "building KvikIO";
        clean-kvikio;
        build-kvikio-cpp;
        build-kvikio-python;
        sccache -s;
    ) 2>&1 | maybe_write_build_log kvikio;

    (
        echo "building cuDF";
        clean-cudf;
    CUDF_ROOT=~/cudf/cpp/build/latest \
    CUDF_INCLUDE_DIR=~/cudf/cpp/include \
    CUDF_KAFKA_ROOT=~/cudf/cpp/libcudf_kafka/build/latest \
    CUDF_KAFKA_INCLUDE_DIR=~/cudf/cpp/libcudf_kafka/include \
    CUDA_HOME="${CONDA_PREFIX:-${CUDA_HOME:-/usr/local/cuda}}" \
    C_INCLUDE_PATH=${C_INCLUDE_PATH:-}:~/rmm/include:~/rmm/build/latest/include \
    CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH:-}:~/rmm/include:~/rmm/build/latest/include \
        build-cudf -DBUILD_BENCHMARKS=ON;
        sccache -s;
    ) 2>&1 | maybe_write_build_log cudf;

    (
        echo "building RAFT";
        clean-raft;
        build-raft -DBUILD_PRIMS_BENCH=ON -DBUILD_ANN_BENCH=ON;
        sccache -s;
    ) 2>&1 | maybe_write_build_log raft;

    (
        echo "building cuMLPrims";
        clean-cumlprims_mg;
        build-cumlprims_mg;
        sccache -s;
    ) 2>&1 | maybe_write_build_log cumlprims_mg;

    (
        echo "building cuML";
        clean-cuml;
        build-cuml;
        sccache -s;
    ) 2>&1 | maybe_write_build_log cuml;

    (
        echo "building cuGraph OPS";
        clean-cugraph-ops;
        build-cugraph-ops;
        sccache -s;
    ) 2>&1 | maybe_write_build_log cugraph-ops;

    (
        echo "building cuGraph";
        clean-cugraph;
    CUDA_HOME="${CONDA_PREFIX:-${CUDA_HOME:-/usr/local/cuda}}" \
        build-cugraph --max-device-obj-memory-usage 5;
        sccache -s;
    ) 2>&1 | maybe_write_build_log cugraph;

    (
        echo "building cuSpatial";
        clean-cuspatial;
        build-cuspatial -DBUILD_TESTS=ON -DBUILD_BENCHMARKS=ON;
        sccache -s;
    ) 2>&1 | maybe_write_build_log cuspatial;

}

(build_rapids "$@");
