# Remove extra libcutensor versions
libcutensor_ver="$(dpkg -s libcutensor1 | grep '^Version:' | cut -d' ' -f2 | cut -d'-' -f1 | cut -d'.' -f4 --complement)";
libcutensorMg_shared="$(find /usr/lib -type f -regex "^.*/libcutensor/${CUDA_VERSION_MAJOR}/libcutensorMg.so.${libcutensor_ver}$")";

if test -n "${libcutensorMg_shared:-}"; then

    libcutensorMg_shared="$(find /usr/lib -type f -regex "^.*/libcutensor/${CUDA_VERSION_MAJOR}/libcutensorMg.so.${libcutensor_ver}$")";
    libcutensorMg_static="$(find /usr/lib -type f -regex "^.*/libcutensor/${CUDA_VERSION_MAJOR}/libcutensorMg_static.a$")";
    libcutensor_shared="$(find /usr/lib -type f -regex "^.*/libcutensor/${CUDA_VERSION_MAJOR}/libcutensor.so.${libcutensor_ver}$")";
    libcutensor_static="$(find /usr/lib -type f -regex "^.*/libcutensor/${CUDA_VERSION_MAJOR}/libcutensor_static.a$")";

    libcutensorMg_shared_link="$(update-alternatives --query libcutensorMg.so.${libcutensor_ver} | grep '^Link:' | cut -d' ' -f2)";
    libcutensorMg_static_link="$(update-alternatives --query libcutensorMg_static.a              | grep '^Link:' | cut -d' ' -f2)";
    libcutensor_shared_link="$(update-alternatives --query libcutensor.so.${libcutensor_ver}     | grep '^Link:' | cut -d' ' -f2)";
    libcutensor_static_link="$(update-alternatives --query libcutensor_static.a                  | grep '^Link:' | cut -d' ' -f2)";

    # Remove existing libcutensor lib alternatives
    (update-alternatives --remove-all libcutensorMg.so.${libcutensor_ver} >/dev/null 2>&1 || true);
    (update-alternatives --remove-all libcutensorMg_static.a              >/dev/null 2>&1 || true);
    (update-alternatives --remove-all libcutensor.so.${libcutensor_ver}   >/dev/null 2>&1 || true);
    (update-alternatives --remove-all libcutensor_static.a                >/dev/null 2>&1 || true);

    # Install only the alternative for the version we keep
    update-alternatives --install "${libcutensorMg_shared_link}" libcutensorMg.so.${libcutensor_ver} "${libcutensorMg_shared}" 0;
    update-alternatives --install "${libcutensorMg_static_link}" libcutensorMg_static.a              "${libcutensorMg_static}" 0;
    update-alternatives --install "${libcutensor_shared_link}"   libcutensor.so.${libcutensor_ver}   "${libcutensor_shared}"   0;
    update-alternatives --install "${libcutensor_static_link}"   libcutensor_static.a                "${libcutensor_static}"   0;

    # Set the default alternative
    update-alternatives --set libcutensorMg.so.${libcutensor_ver} "${libcutensorMg_shared}";
    update-alternatives --set libcutensorMg_static.a              "${libcutensorMg_static}";
    update-alternatives --set libcutensor.so.${libcutensor_ver}   "${libcutensor_shared}";
    update-alternatives --set libcutensor_static.a                "${libcutensor_static}";
fi

rm -rf $(find /usr/lib -mindepth 1 -type d -regex "^.*/libcutensor/.*$" | grep -Ev "^.*/libcutensor/${CUDA_VERSION_MAJOR}$");
