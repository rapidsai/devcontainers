
# OpenMPI (openmpi)

A feature to install OpenMPI with optional CUDA and UCX support

## Example Usage

```json
"features": {
    "ghcr.io/rapidsai/devcontainers/features/openmpi:25": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | OpenMPI version to install (defaults to system). | string | system |

Installs one of the OpenMPI releases listed [here](https://www.open-mpi.org/software/ompi).


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rapidsai/devcontainers/blob/main/features/src/openmpi/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
