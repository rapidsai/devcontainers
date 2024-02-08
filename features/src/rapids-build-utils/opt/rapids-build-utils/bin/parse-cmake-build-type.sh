#!/usr/bin/env bash

rapids-parse-cmake-define CMAKE_BUILD_TYPE "$@" <&0 || echo "Release";
