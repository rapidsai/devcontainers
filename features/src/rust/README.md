
# Rust (rust)

Installs Rust, common Rust utilities, and their required dependencies

## Example Usage

```json
"features": {
    "ghcr.io/trxcllnt/devcontainer-features/rust:2": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a version of Rust to install. | string | latest |
| profile | Select a rustup install profile. | string | minimal |
| updateRc | - | boolean | true |
| updateRust | - | boolean | false |



## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/trxcllnt/devcontainer-features/blob/main/src/rust/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
