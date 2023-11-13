
# LLVM compilers and tools (llvm)

A feature to install LLVM compilers and tools

## Example Usage

```json
"features": {
    "ghcr.io/rapidsai/devcontainers/features/llvm:24": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | LLVM version to install. | string | dev |
| packages | LLVM packages to install. | string | all |

## Customizations

### VS Code Extensions

- `cschlosser.doxdocgen`
- `llvm-vs-code-extensions.vscode-clangd`
- `ms-vscode.cpptools`
- `vadimcn.vscode-lldb`
- `seaube.clangformat`



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/rapidsai/devcontainers/blob/main/features/src/llvm/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
