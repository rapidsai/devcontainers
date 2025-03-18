if test -z "${DISABLE_SCCACHE+x}"; then
    # Log sccache server messages
    export SCCACHE_ERROR_LOG="${SCCACHE_ERROR_LOG:-/var/log/devcontainer-utils/sccache.log}";
    export SCCACHE_SERVER_LOG="${SCCACHE_SERVER_LOG:-sccache=info}";

    # Use sccache for Rust, C, C++, and CUDA compilations
    if ! test -v RUSTC_WRAPPER; then
        export RUSTC_WRAPPER="${RUSTC_WRAPPER:-/usr/bin/sccache}";
    fi
    if ! test -v CMAKE_C_COMPILER_LAUNCHER; then
        export CMAKE_C_COMPILER_LAUNCHER="${CMAKE_C_COMPILER_LAUNCHER:-/usr/bin/sccache}";
    fi
    if ! test -v CMAKE_CXX_COMPILER_LAUNCHER; then
        export CMAKE_CXX_COMPILER_LAUNCHER="${CMAKE_CXX_COMPILER_LAUNCHER:-/usr/bin/sccache}";
    fi
    if ! test -v CMAKE_CUDA_COMPILER_LAUNCHER; then
        export CMAKE_CUDA_COMPILER_LAUNCHER="${CMAKE_CUDA_COMPILER_LAUNCHER:-/usr/bin/sccache}";
    fi
fi
