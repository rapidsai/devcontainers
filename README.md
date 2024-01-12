# RAPIDS [devcontainers](https://containers.dev/)

This repository contains features and workflows for building development
containers to support local dev and CI for NVIDIA
[RAPIDS](https://github.com/rapidsai), [CCCL](https://github.com/nvidia/cccl),
and [Legate](https://github.com/nv-legate).
[Devcontainers](https://containers.dev/) are an open standard for specifying the
creation and execution of Docker containers for developing a codebase. It's like
using a docker image to develop, but there's some extra configuration and
installation that can be done. It also provides some alternative ways of
composing functionality and configuration that can augment Docker's
capabilities.

In addition to scripts that set up the devcontainer environment for things like GitHub auth, this repo contains reusable scripts to install software in arbitrary containers, aiding in composition and code sharing. A "feature" in VSCode terms refers to these installation scripts. The script for each feature runs when creating the devcontainer.

We've chosen to use a monorepo for the features here, but it is similar in spirit to the official [devcontainers/features](https://github.com/devcontainers/features) and [devcontainers/images](https://github.com/devcontainers/images) repositories.

## For details on using the RAPIDS devcontainers, see [`USAGE.md`](USAGE.md).

## For details on contributing to this repository, see [`DEVELOP.md`](DEVELOP.md).
## See the list of `rapidsai/devcontainers` tags [on DockerHub](https://hub.docker.com/r/rapidsai/devcontainers/tags). These tags are used as base images in devcontainers, and aren't really meant to be used directly.
