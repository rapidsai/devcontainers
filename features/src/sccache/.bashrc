if test -z "${DISABLE_SCCACHE:+x}"; then
    # Log sccache server messages
    export SCCACHE_SERVER_LOG="${SCCACHE_SERVER_LOG:-sccache=info}";
    export SCCACHE_ERROR_LOG="${SCCACHE_ERROR_LOG:-/tmp/sccache.log}";
    # Use sccache for Rust, C, C++, and CUDA compilations
    export RUSTC_WRAPPER="${RUSTC_WRAPPER:-/usr/bin/sccache}";
    export CMAKE_C_COMPILER_LAUNCHER="${CMAKE_C_COMPILER_LAUNCHER:-/usr/bin/sccache}";
    export CMAKE_CXX_COMPILER_LAUNCHER="${CMAKE_CXX_COMPILER_LAUNCHER:-/usr/bin/sccache}";
    export CMAKE_CUDA_COMPILER_LAUNCHER="${CMAKE_CUDA_COMPILER_LAUNCHER:-/usr/bin/sccache}";
fi
