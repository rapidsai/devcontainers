export NVARCH="${NVARCH}";
export CUDA_HOME="${CUDA_HOME}";
export CUDA_PATH="${CUDA_HOME}";
export CUDA_VERSION="${CUDA_VERSION}";
export CUDA_VERSION_MAJOR="${CUDA_VERSION_MAJOR}";
export CUDA_VERSION_MINOR="${CUDA_VERSION_MINOR}";
export CUDA_VERSION_PATCH="${CUDA_VERSION_PATCH}";

if [ -n "${PATH##*"/usr/local/nvidia/bin:${CUDA_HOME}/bin"*}" ]; then
    export PATH="/usr/local/nvidia/bin:${CUDA_HOME}/bin:${PATH}";
fi

if [ -z "${LIBRARY_PATH:-}" ] \
|| [ -n "${LIBRARY_PATH##*"${CUDA_HOME}/lib64/stubs"*}" ]; then
    export LIBRARY_PATH="${CUDA_HOME}/lib64/stubs${LIBRARY_PATH:+:$LIBRARY_PATH}"
fi

if [ -z "${LD_LIBRARY_PATH:-}" ] \
|| [ -n "${LD_LIBRARY_PATH##*"/usr/local/nvidia/lib:/usr/local/nvidia/lib64"*}" ]; then
    export LD_LIBRARY_PATH="/usr/local/nvidia/lib:/usr/local/nvidia/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi
