# Using the RAPIDS devcontainers

### See the list of `rapidsai/devcontainers` tags [on DockerHub](https://hub.docker.com/r/rapidsai/devcontainers/tags).

* [Using the pre-built images](#using-the-pre-built-images)
  * [Using in `devcontainer.json`](#using-in-devcontainerjson)
* [Build caching with sccache](#build-caching-with-sccache)


## Using the pre-built images

We publish a [matrix](matrix.yml) of pre-built images to DockerHub to accelerate initializing local devcontainers, GitHub Codespaces, and CI jobs.

The features that comprise the image are noted in the image tags. If no version is defined for a tool or SDK, the image includes the latest available version at image build time.

> **NOTE:** `git`, `git-lfs`, `github-cli`, `gitlab-cli`, `cmake`, `ninja`, `sccache`, and our devcontainer-utils [are included](image/.devcontainer/devcontainer.json#L12-L33) in each pre-built image.

### Using in [`devcontainer.json`](https://containers.dev/implementors/json_reference/#image-specific)

The pre-built images can be used as the `"image"`, or as the base of a Dockerfile in `"build"`, in `devcontainer.json`:

<details><summary>devcontainer.json using pre-built image</summary><pre>{<br/>  "image": "rapidsai/devcontainers:24.12-cpp-llvm16-cuda12.0-nvhpc23.5-ubuntu22.04",<br/>  "hostRequirements": { "gpu": true },<br/>  "workspaceFolder": "/home/coder/${localWorkspaceFolderBasename}",<br/>  "workspaceMount": "source=${localWorkspaceFolder},target=/home/coder/${localWorkspaceFolderBasename},type=bind"<br/>}</pre></details>

You can also build a custom devcontainer by composing individual features:

<details><summary>devcontainer.json using individual features</summary><pre>{<br/>  "image": "ubuntu:22.04",<br/>  "features": {<br/>    "ghcr.io/rapidsai/devcontainers/features/cmake:24.12": {},<br/>    "ghcr.io/rapidsai/devcontainers/features/ninja:24.12": {},<br/>    "ghcr.io/rapidsai/devcontainers/features/sccache:24.12": {<br/>      "version": "0.5.4"<br/>    }<br/>  },<br/>  "overrideFeatureInstallOrder": [<br/>    "ghcr.io/rapidsai/devcontainers/features/cmake",<br/>    "ghcr.io/rapidsai/devcontainers/features/ninja",<br/>    "ghcr.io/rapidsai/devcontainers/features/sccache"<br/>  ],<br/>  "workspaceFolder": "/home/coder/${localWorkspaceFolderBasename}",<br/>  "workspaceMount": "source=${localWorkspaceFolder},target=/home/coder/${localWorkspaceFolderBasename},type=bind"<br/>}</pre></details>

> **NOTE:** Feature updates published since your most recent image build will invalidate your docker image layer cache, meaning it can take the [devcontainers CLI](https://github.com/devcontainers/cli) longer to initialize containers composed from individual features.

## Build caching with `sccache`

The devcontainers configure CMake to use [sccache](https://github.com/mozilla/sccache) as C, C++, CUDA, and Rust compiler launchers. Refer to the [sccache docs](https://github.com/mozilla/sccache/tree/main/docs) for configuring the various storage back-ends.

### Build caching with private S3 buckets

You can use a private S3 bucket as the `sccache` storage back-end.

If you're using a [GitHub action](https://github.com/aws-actions/configure-aws-credentials) to assume AWS roles in CI, or are comfortable distributing and managing S3 credentials, you can define the `SCCACHE_BUCKET`, `AWS_ACCESS_KEY_ID`, and `AWS_SECRET_ACCESS_KEY` variables in the container environment.

### Using GitHub OAuth to issue S3 credentials via Hashicorp Vault

The [`devcontainer-utils`](features/src/utils/) feature includes a `devcontainer-utils-vault-s3-init` script that uses GitHub OAuth and Hashicorp Vault to issue temporary S3 credentials to authorized users.

> **NOTE:** This script runs in the devcontainer's [`postAttachCommand`](https://containers.dev/implementors/json_reference/#lifecycle-scripts), but it does nothing unless `SCCACHE_BUCKET` and `VAULT_HOST` are in the container environment.

The `devcontainer-utils-vault-s3-init` script performs the following actions, exiting early if any step is unsuccessful:

1. Log in via the [GitHub CLI](https://cli.github.com/)
2. Authenticate via [Vault's GitHub auth method](https://developer.hashicorp.com/vault/docs/auth/github#authentication)
3. Use Vault to [generate temporary AWS credentials](https://developer.hashicorp.com/vault/api-docs/secret/aws#generate-credentials)
4. Store results in `~/.aws` and install crontab to re-authenticate

The above steps can be customized via the following environment variables:
```
# The hostname of the Vault instance to use
VAULT_HOST="https://vault.ops.k8s.rapids.ai"

# List of GitHub organizations for which Vault can generate credentials.
# The scripts assumes the Vault instance exposes an authentication endpoint
# for each org at `$VAULT_HOST/v1/auth/github-$org/login`.
# https://developer.hashicorp.com/vault/docs/auth/github#authentication
VAULT_GITHUB_ORGS="nvidia nv-morpheus nv-legate rapids"

# The TTL for the generated AWS credentials
VAULT_S3_TTL=28800

# The URI to the Vault API that generates AWS credentials
# The full URL expands to `$VAULT_HOST/$VAULT_S3_URI?ttl=$VAULT_S3_TTL`
# https://developer.hashicorp.com/vault/api-docs/secret/aws#generate-credentials
VAULT_S3_URI="v1/aws/creds/devs"
```
