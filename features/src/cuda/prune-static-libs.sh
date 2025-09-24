if test -n "${libcutensorMg_static:+x}" && test -f "${libcutensorMg_static}"; then
    rm -rf "${libcutensorMg_static}";
    (update-alternatives --remove-all libcutensorMg_static.a >/dev/null 2>&1 || true);
fi

if test -n "${libcutensor_static:+x}" && test -f "${libcutensor_static}"; then
    rm -rf "${libcutensor_static}";
    (update-alternatives --remove-all libcutensor_static.a   >/dev/null 2>&1 || true);
fi

find /usr/lib/                                       \
    \( -type f -or -type l \)                        \
    \( -name 'libnccl*.a' -or -name 'libcudnn*.a' \) \
    -delete \
 || true;

for dir in "lib" "lib64"; do
    if [ -d "${CUDA_HOME}/${dir}/" ]; then
        find "$(realpath -m "${CUDA_HOME}/${dir}")/" -type f \
            \( -name '*.a' ! -name 'libnvptxcompiler_static.a' ! -name 'libcudart_static.a' ! -name 'libcudadevrt.a' ! -name 'libculibos.a' ! -name 'libcufilt.a' \) \
            -delete || true;
    fi
done
