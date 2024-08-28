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
    # needed by libcuspatial
    libgdal-dev \
    sqlite3 \
    libsqlite3-dev \
    libtiff-dev \
    libcurl4-openssl-dev \
 && rm -rf /tmp/* /var/tmp/* /var/cache/apt/* /var/lib/apt/lists/*;

# https://github.com/conda-forge/aws-sdk-cpp-feedstock/blob/main/recipe/meta.yaml
# https://github.com/conda-forge/aws-sdk-cpp-feedstock/blob/main/recipe/build.sh
# maybe we don't need -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
ENV AWS_SDK_VER=1.11.379
RUN curl -L -o /tmp/aws-sdk-cpp.tar.gz https://github.com/aws/aws-sdk-cpp/archive/${AWS_SDK_VER}.tar.gz \
    && tar xvzf aws-sdk-cpp.tar.gz && cd aws-sdk-cpp-${AWS_SDK_VER} \
    && mkdir -p aws-sdk-cpp-${AWS_SDK_VER}/build \
    && cd aws-sdk-cpp-${AWS_SDK_VER}/build \
    && cmake ${CMAKE_ARGS} .. -GNinja \
       -DCMAKE_INSTALL_LIBDIR=lib \
       -DCMAKE_MODULE_PATH="/usr/lib/cmake" \
       -DBUILD_ONLY='s3;core;transfer;config;identity-management;sts;sqs;sns;monitoring;logs' \
       -DCMAKE_POLICY_DEFAULT_CMP0075=NEW \
       -DENABLE_UNITY_BUILD=ON \
       -DENABLE_TESTING=OFF \
       -DCMAKE_BUILD_TYPE=Release \
       -DBUILD_DEPS=OFF \
       -DCURL_HAS_H2=ON \
       -DCURL_HAS_TLS_PROXY=ON \
     ninja install 

ENV DEFAULT_VIRTUAL_ENV=rapids

FROM ${BASE} as conda-base

ENV DEFAULT_CONDA_ENV=rapids

FROM ${PYTHON_PACKAGE_MANAGER}-base

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
ENV VAULT_HOST="https://vault.ops.k8s.rapids.ai"
ENV HISTFILE="/home/coder/.cache/._bash_history"

ENV LIBCUDF_KERNEL_CACHE_PATH="/home/coder/cudf/cpp/build/${PYTHON_PACKAGE_MANAGER}/cuda-${CUDA_VERSION}/latest/jitify_cache"
