export NVARCH="${NVARCH}";

export CUDA_HOME="${CUDA_HOME}";
export CUDA_VERSION="${CUDA_VERSION}";
export CUDA_VERSION_MAJOR="${CUDA_VERSION_MAJOR}";
export CUDA_VERSION_MINOR="${CUDA_VERSION_MINOR}";
export CUDA_VERSION_PATCH="${CUDA_VERSION_PATCH}";

export LIBRARY_PATH="${LIBRARY_PATH}";
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}";

if [ -n "${PATH##*"/usr/local/nvidia/bin:${CUDA_HOME}/bin"*}" ]; then
    export PATH="/usr/local/nvidia/bin:${CUDA_HOME}/bin:${PATH}";
fi
