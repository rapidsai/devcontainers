#! /usr/bin/env bash

# Configures the system to use the CUDA forward compatibility libraries
# (cuda-compat) in preference to the host driver libraries.
#
# This script is installed into the image by the `cuda` feature and is
# intended to be invoked from container entrypoints. It is a no-op unless
# the feature was installed with `installCudaCompat: true`, which sets
# CUDA_COMPAT_INSTALLED=true in the container environment.

set -euo pipefail;

# Only configure the system if cuda-compat was installed by the cuda feature.
if [ "${CUDA_COMPAT_INSTALLED:-false}" != "true" ]; then
    exit 0;
fi

# WSL hosts pass the Windows driver through to containers, so the compat
# libraries are unnecessary there.
if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "WSL host detected, skipping cuda-compat configuration.";
    exit 0;
fi

compat_dir="${CUDA_HOME:-/usr/local/cuda}/compat";

if [ ! -d "${compat_dir}" ]; then
    echo "CUDA_COMPAT_INSTALLED is true, but '${compat_dir}' does not exist." >&2;
    exit 1;
fi

# Run privileged commands via sudo unless already running as root.
if [ "$(id -u)" = 0 ]; then
    as_root() { "$@"; };
else
    as_root() { sudo "$@"; };
fi

# Point the dynamic linker at the compat libraries so they take precedence
# over the host driver libs. The conf file sorts before the system library
# dirs in ldconfig's search order, giving the compat libs precedence.
as_root tee /etc/ld.so.conf.d/cuda-compat.conf <<< "${compat_dir}" > /dev/null;
as_root ldconfig;

echo "cuda-compat forward compatibility libraries configured from '${compat_dir}'.";
