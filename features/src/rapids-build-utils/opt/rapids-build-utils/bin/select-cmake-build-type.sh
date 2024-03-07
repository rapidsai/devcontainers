#!/usr/bin/env bash

rapids-select-cmake-define CMAKE_BUILD_TYPE "$@" <&0 || echo "Release";
