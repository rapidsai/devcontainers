# RAPIDS [Development Containers](https://containers.dev/)

[Click here to see the list of `rapidsai/devcontainers` tags available in DockerHub.](https://hub.docker.com/r/rapidsai/devcontainers/tags)

This repository contains development containers and features supporting containerized development and continuous integration for the NVIDIA [RAPIDS](https://github.com/rapidsai), [CCCL](https://github.com/nvidia/cccl), and [Legate](https://github.com/nv-legate) projects.

This repo is similar in spirit to the [devcontainers/features](https://github.com/devcontainers/features) and [devcontainers/images](https://github.com/devcontainers/images) repos.

## Pre-built [Images](https://hub.docker.com/r/rapidsai/devcontainers/tags)

We publish a [matrix](matrix.yml) of pre-built images to DockerHub to accelerate local devcontainers, GitHub Codespaces, and CI jobs. The images are composed of [features](https://containers.dev/implementors/features/), many of which are also defined in this repository (see [Features](#features) below).

All the prebuilt images [contain](image/.devcontainer/devcontainer.json#L12-L33) `git`, `git-lfs`, `github-cli`, `gitlab-cli`, `cmake`, `ninja`, `sccache`, and our devcontainer utility scripts to automate certain in-container tasks. The images in `matrix.yml` extend this set of features by adding various dev tools, compilers, and SDKs.

## Reusable [Features](features/src/)

From the official devcontainer [documentation on Features](https://containers.dev/implementors/features/):
> Development container "Features" are self-contained, shareable units of installation code and development container configuration.

In short, a "feature" is a layer in a Dockerfile which encapsulates a reusable bit of logic executed when building a Docker image.

This repository defines features to install the following dev tools, compilers, and SDKs:

* [CMake](features/src/cmake/)
* [CUDA Toolkit](features/src/cuda/)
* [GCC](features/src/gcc/)
* [GitLab CLI](features/src/gitlab-cli/)
* [LLVM](features/src/llvm/)
* [Mambaforge](features/src/mambaforge/)
* [ninja-build](features/src/ninja/)
* [NVIDIA HPC SDK](features/src/nvhpc/)
* [Intel OneAPI compilers (icc/icpc/icx/icpx)](features/src/oneapi/)
* [lit (from pypi)](features/src/python-lit/)
* [Rust](features/src/rust/)
* [sccache](features/src/sccache/)
* [devcontainer-utils](features/src/utils/)
* [rapids-build-utils](features/src/rapids-build-utils/)
