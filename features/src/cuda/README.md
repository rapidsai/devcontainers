
# CUDA Toolkit (cuda)

A feature to install the NVIDIA CUDA Toolkit

## Example Usage

```json
"features": {
    "ghcr.io/rapidsai/devcontainers/features/cuda:23": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Version of the CUDA Toolkit to install. | string | 12.1 |
| pruneStaticLibs | Whether to remove static libs from the CUDA Toolkit to save image size | boolean | true |

## Customizations

### VS Code Extensions

- `ms-vscode.cpptools`
- `nvidia.nsight-vscode-edition`



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rapidsai/devcontainers/blob/main/features/src/cuda/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
