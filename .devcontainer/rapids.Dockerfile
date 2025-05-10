# syntax=docker/dockerfile:1.5

ARG BASE
ARG PYTHON_PACKAGE_MANAGER=conda

FROM ${BASE} as pip-base

RUN apt update -y \
 && DEBIAN_FRONTEND=noninteractive apt install -y --no-install-recommends \
    # C++ build tools
    doxygen \
    graphviz \
    # C++ test dependencies
    libgmock-dev \
    libgtest-dev \
    # needed by libcudf_kafka
    librdkafka-dev \
    # cuML/cuGraph dependencies
    libblas-dev \
    liblapack-dev \
 && rm -rf /tmp/* /var/tmp/* /var/cache/apt/* /var/lib/apt/lists/*;

ENV DEFAULT_VIRTUAL_ENV=rapids

ENV RAPIDS_LIBUCX_PREFER_SYSTEM_LIBRARY=true

FROM ${BASE} as conda-base

ENV DEFAULT_CONDA_ENV=rapids

FROM ${PYTHON_PACKAGE_MANAGER}-base

ARG TARGETARCH

ARG CUDA
ENV CUDAARCHS="RAPIDS"
ENV CUDA_VERSION="${CUDA_VERSION:-${CUDA}}"

ARG PYTHON_PACKAGE_MANAGER
ENV PYTHON_PACKAGE_MANAGER="${PYTHON_PACKAGE_MANAGER}"

ENV PYTHONSAFEPATH="1"
ENV PYTHONUNBUFFERED="1"
ENV PYTHONDONTWRITEBYTECODE="1"

ENV SCCACHE_REGION="us-east-2"
ENV SCCACHE_BUCKET="rapids-sccache-devs"
ENV SCCACHE_DIST_CONNECT_TIMEOUT=30
ENV SCCACHE_DIST_REQUEST_TIMEOUT=7200
ENV SCCACHE_DIST_KEEPALIVE_ENABLED=true
ENV SCCACHE_DIST_KEEPALIVE_INTERVAL=20
ENV SCCACHE_DIST_KEEPALIVE_TIMEOUT=600
ENV SCCACHE_DIST_URL="https://${TARGETARCH}.linux.sccache.gha-runners.nvidia.com"
ENV SCCACHE_IDLE_TIMEOUT=1800
ENV AWS_ROLE_ARN="arn:aws:iam::279114543810:role/nv-gha-token-sccache-devs"

ENV HISTFILE="/home/coder/.cache/._bash_history"

ENV LIBCUDF_KERNEL_CACHE_PATH="/home/coder/cudf/cpp/build/${PYTHON_PACKAGE_MANAGER}/cuda-${CUDA_VERSION}/latest/jitify_cache"

# Prevent the sccache server from shutting down
ENV SCCACHE_IDLE_TIMEOUT=0
ENV SCCACHE_SERVER_LOG="sccache=info"
ENV SCCACHE_S3_KEY_PREFIX=rapids-test-sccache-dist

# Build as much in parallel as possible
ENV INFER_NUM_DEVICE_ARCHITECTURES=1
ENV MAX_DEVICE_OBJ_TO_COMPILE_IN_PARALLEL=20
