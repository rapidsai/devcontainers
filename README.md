# RAPIDS [devcontainers](https://containers.dev/)

This repository contains centralized features and workflows for building
development containers ([devcontainers](https://containers.dev/)) to support
local dev and CI for projects in NVIDIA [RAPIDS](https://github.com/rapidsai),
[CCCL](https://github.com/nvidia/cccl), and
[Legate](https://github.com/nv-legate).

[Devcontainers](https://containers.dev/) are an open standard for specifying the
creation and execution of Docker containers for developing a codebase.

Downstream repositories that utilize devcontainers use both the `feature`
scripts that install software, as well as docker images that serve to cache sets
of installed software. These images serve as base images for the devcontainers
specified in the downstream repositories.

## Usage

### [Using devcontainers to provide a build environment on a project](./USAGE_IN_PROJECT.md)

### [Setting up and maintaining devcontainer configuration in other projects](./USAGE.md)

### [Developing the centralized `feature` scripts and base images in this repository](DEVELOP.md).
