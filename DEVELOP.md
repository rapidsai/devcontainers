# Contributing to the RAPIDS devcontainers

## Features

From the official devcontainer [documentation on Features](https://containers.dev/implementors/features/):
> Development container "Features" are self-contained, shareable units of installation code and development container configuration.

In short, a "feature" is a layer in a Dockerfile which encapsulates a reusable
bit of logic executed when building a Docker image. It is not a docker layer to
put on top of or copied into other layers. It is the script that creates a
layer.

This repository defines features to install the following dev tools, compilers, and SDKs:

* [CMake](features/src/cmake/)
* [CUDA Toolkit](features/src/cuda/)
* [GCC](features/src/gcc/)
* [GitLab CLI](features/src/gitlab-cli/)
* [LLVM](features/src/llvm/)
* [Mambaforge](features/src/mambaforge/)
* [ninja-build](features/src/ninja/)
* [NVIDIA HPC SDK](features/src/nvhpc/)
* [Intel OneAPI compilers](features/src/oneapi/)
* [CCCL development utilities](features/src/cccl-dev/)
* [Rust](features/src/rust/)
* [sccache](features/src/sccache/)
* [devcontainer-utils](features/src/utils/)
* [rapids-build-utils](features/src/rapids-build-utils/)

These scripts assume that apt utilities are available, and thus only run on debian-based images.

## Base images

Base images are composed in [matrix.yml](./matrix.yml) using [YAML anchors](https://support.atlassian.com/bitbucket-cloud/docs/yaml-anchors/). These get built on Github Actions ([release.yml](./.github/workflows/release.yml) and [test.yml](.github/workflows/test.yml))