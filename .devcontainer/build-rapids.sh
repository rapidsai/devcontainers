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
        build-rmm -DBUILD_BENCHMARKS=ON --verbose;
        sccache -s;
    ) 2>&1 | maybe_write_build_log rmm;

    (
        echo "building KvikIO";
        clean-kvikio;
        build-kvikio --verbose;
        sccache -s;
    ) 2>&1 | maybe_write_build_log kvikio;

    (
        echo "building ucxx";
        clean-ucxx;
        build-ucxx --verbose;
        sccache -s;
    ) 2>&1 | maybe_write_build_log ucxx;

    (
        echo "building cuDF";
        clean-cudf;
        build-cudf -DBUILD_BENCHMARKS=ON --verbose
        sccache -s;
    ) 2>&1 | maybe_write_build_log cudf;

    (
        echo "building RAFT";
        clean-raft;
        build-raft -DBUILD_PRIMS_BENCH=ON --verbose;
        sccache -s;
    ) 2>&1 | maybe_write_build_log raft;

    (
        echo "building cuML";
        clean-cuml;
        build-cuml --verbose;
        sccache -s;
    ) 2>&1 | maybe_write_build_log cuml;

    (
        echo "building wholegraph";
        clean-wholegraph;
        build-wholegraph --verbose;
        sccache -s;
    ) 2>&1 | maybe_write_build_log wholegraph;

    (
        echo "building cuGraph";
        clean-cugraph;
    CUDA_HOME="${CONDA_PREFIX:-${CUDA_HOME:-/usr/local/cuda}}" \
        build-cugraph --verbose --max-device-obj-memory-usage 5;
        sccache -s;
    ) 2>&1 | maybe_write_build_log cugraph;

}

(build_rapids "$@");
