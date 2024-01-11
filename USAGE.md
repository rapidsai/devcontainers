# Using the RAPIDS devcontainers

- [Using the RAPIDS devcontainers](#using-the-rapids-devcontainers)
  - [Quick start](#quick-start)
  - [Detailed start](#detailed-start)
    - [Using devcontainers in VS Code](#using-devcontainers-in-vs-code)
    - [Using devcontainers from the terminal](#using-devcontainers-from-the-terminal)
    - [Generated build scripts](#generated-build-scripts)
    - [rapids-build-utils](#rapids-build-utils)
    - [Native build tools - CMake, python builds](#native-build-tools---cmake-python-builds)
    - [Exiting the devcontainer](#exiting-the-devcontainer)
  - [Adding projects: `manifest.yaml` file](#adding-projects-manifestyaml-file)
  - [Using the pre-built images](#using-the-pre-built-images)
    - [Using in `devcontainer.json`](#using-in-devcontainerjson)
    - [Custom devcontainers](#custom-devcontainers)
  - [Build caching with `sccache`](#build-caching-with-sccache)
    - [Build caching with private S3 buckets](#build-caching-with-private-s3-buckets)
    - [Using GitHub OAuth to issue S3 credentials via Hashicorp Vault](#using-github-oauth-to-issue-s3-credentials-via-hashicorp-vault)

## Quick start

If you really want to get started right away and ignore all the details of how
devcontainers work, the easiest way is to treat the devcontainer
like a docker container that you use interactively. Brad Dice wrote [a script
that wraps the devcontainer
CLI](https://gist.github.com/bdice/a92d224b3e3b1b387fc18b8095b3bdbd) to do this.

To obtain this script:
```
curl -LO https://gist.githubusercontent.com/bdice/a92d224b3e3b1b387fc18b8095b3bdbd/raw/28eb8edc856ae04d4cd83571fea5b894f714f01c/rapids-dev
chmod +x rapids-dev
./rapids-dev
```

This script expects you to have your current directory set to the
root of a repo that has a .devcontainer folder. You may want to move
this script to a folder that you place on PATH, such as `~/bin`

Running that command will build the devcontainer and drop you at
an interactive prompt. You can immediately build your project
with one of the devcontainers scripts. Type `build-` and hit `<TAB>` to see your options.

Skip ahead to [Available tools in the devcontainer](#available-tools-in-the-devcontainer) to see more options
for interaction at this prompt.

## Detailed start

So, you have cloned a repo that you've heard has a devcontainer. You can see the file(s) for yourself by looking
in your repo's `.devcontainer` folder. You may find a `devcontainer.json` file, or you may find some number of folders, such as `cuda12.0-conda` and `cuda12.0-pip`. If you find folders, these each contain a `devcontainer.json`
file. These files specify how to create and run a container that leaves you with a good setup to do development.

There are at least 2 ways to consume these devcontainer.json files. VS Code was
the original home of devcontainers prior to becoming an open specification, and
it remains a good way to use them. If you prefer not to use VS Code, the
[devcontainers-cli](https://code.visualstudio.com/docs/devcontainers/devcontainer-cli)
application will build the devcontainer and allow you to interact with it.

### Using devcontainers in VS Code

[The VS Code
docs](https://code.visualstudio.com/docs/devcontainers/containers#_quick-start-open-an-existing-folder-in-a-container)
are the definitive source of information for this topic.

Specifically for RAPIDS repos, we frequently have multiple folders for different
library configurations. Pay attention to which build environment you need when
launching your devcontainer. You can switch between them by reopening your
native host (e.g. CMD+SHIFT+P -> "Reopen folder in SSH"), and then re-opening in
devcontainer (CMD+SHIFT+P -> "Reopen in container"), at which point you'll see a
prompt to choose a different `devcontainer.json`.

### Using devcontainers from the terminal

The [devcontainer-cli](https://code.visualstudio.com/docs/devcontainers/devcontainer-cli) project
allows you to run and interact with devcontainers from the terminal. It uses NodeJS, so you need
to install that in order to run it.

There are wrappers to facilitate working with this CLI. Refer back to the
[Quick-start section](#quick-start). If you need more flexibility, you can call
the devcontainer CLI directly.

You need to specify the `devcontainer.json` file and workspace folder to use when starting the devcontainer. Also note that you must manage the 3 steps of the lifecycle yourself:

* bring up the devcontainer
* run your command (or run bash for interactive prompt)
* stop and remove the docker container

```
CONTAINER_JSON=.devcontainer/cuda12.0-pip/devcontainer.json
devcontainer up --config ${CONTAINER_JSON} --workspace-folder=$(pwd)
devcontainer exec --config ${CONTAINER_JSON} --workspace-folder=$(pwd) bash
```

Stopping and removing the docker container is manual. The devcontainer CLI does
not currently facilitate this in any way. One possible workflow (copied from [aforementioned wrapper](https://gist.github.com/bdice/a92d224b3e3b1b387fc18b8095b3bdbd)):

```
CONTAINER_ID=$(docker ps --quiet \
      --filter label=devcontainer.local_folder=$(pwd) \
      --filter label=devcontainer.config_file=${CONTAINER_JSON})
num_active_shells=$(docker exec "${container_id}" ps aux | grep -c "/bin/sh")
if [[ ${num_active_shells} -le 1 ]]; then
    echo "All devcontainers are closed. Stopping and removing container ${container_id}."
    docker stop "${container_id}"
    docker rm "${container_id}"
fi
```

### Generated build scripts

Several scripts are generated for you based on the contents of manifest.yaml. By
default, `manifest.yaml` comes from [the RAPIDS/devcontainers
repo](https://github.com/rapidsai/devcontainers/blob/branch-24.02/features/src/rapids-build-utils/opt/rapids-build-utils/manifest.yaml),
but you can use your own local `manifest.yaml` file. Refer to the "Adding
projects" section.

The generated scripts are:
* `/usr/bin/build-*`
* `/usr/bin/clean-*`
* `/usr/bin/clone-*`
* `/usr/bin/configure-*`

Here the `*` is a placeholder for the project name and the kind of
build. For example, a project with a python component in `manifest.yaml`
will have `build-cudf-python`.

These scripts may trigger side-effects. For example, `build-*` scripts are only
generated for projects that exist in the workspace. If you are working on `cudf`,
which depends on `rmm`, the default workspace only mounts `cudf` and generates
`build-cudf` scripts. If you want `rmm` build scripts also, you can run `clone-rmm`,
which will clone `rmm` into your workspace and generate build scripts for it.

### rapids-build-utils

These are meta-build scripts. They assist with setting up the workspace and reloading things when important configuration
changes happen. You mostly won't need to worry about these,
but it's good to be aware of them. They come from the [rapidsai/devcontainers repo](https://github.com/rapidsai/devcontainers/tree/branch-24.02/features/src/rapids-build-utils/opt/rapids-build-utils/bin)

### Native build tools - CMake, python builds

The generated scripts mentioned above will take care of running
build tools for you. However, if you need to run the build tools
manually, you can `cd` into your source code folder, which is
mounted as a subfolder in `/home/coder`.

### Exiting the devcontainer

If you are in VS Code and you need to return to your host machine (local or SSH),
you can run `Dev Containers: Reopen in SSH`.

## Adding projects: `manifest.yaml` file

The build script generation is controlled with a `manifest.yaml` file, which by default comes from [the rapidsai/devcontainers
repo](https://github.com/rapidsai/devcontainers/blob/branch-24.02/features/src/rapids-build-utils/opt/rapids-build-utils/manifest.yaml)

If you would like to add your project, you can submit a PR to the rapidsai/devcontainers repo. Before you do that, though, you can
test it locally. Start by copying `manifest.yaml` from the rapidsai/devcontainers repo. You can put it anywhere, but let's say we put it in .devcontainer/manifest.yaml.

Now open a devcontainer.json file that you want to work with. These
will likely live in a .devcontainer subfolder, such as cuda12.0-pip. In this file, add a top-level key with this:

```
 "containerEnv": {
   "PROJECT_MANIFEST_YML": "${localWorkspaceFolder}/.devcontainer/manifest.yaml"
 },
```

Rebuild or re-open your devcontainer, and you should now see updated
generated scripts.

## Using the pre-built images

The choice of using a pre-built image refers to the build/args/BASE entry in `devcontainer.json`. The pre-built
images are not meant to be used directly. The rapids-build-utils scripts are installed with a "feature," so
they won't be present if you directly run a pre-built image with Docker instead of with a devcontainer tool (VS Code or devcontainer-cli)

We publish a [matrix](matrix.yml) of pre-built images to DockerHub to accelerate initializing local devcontainers, GitHub Codespaces, and CI jobs. These use the "feature" scripts to install their components,
so you can think of them as caching those steps.

The features that comprise the image are noted in the image tags. If no version is defined for a tool or SDK, the image includes the latest available version at image build time.

> **NOTE:** `git`, `git-lfs`, `github-cli`, `gitlab-cli`, `cmake`, `ninja`, `sccache`, and our devcontainer-utils [are included](image/.devcontainer/devcontainer.json#L12-L33) in each pre-built image.

See the list of `rapidsai/devcontainers` tags [on DockerHub](https://hub.docker.com/r/rapidsai/devcontainers/tags).

### Using in [`devcontainer.json`](https://containers.dev/implementors/json_reference/#image-specific)

The pre-built images can be used as the `"image"`, or as the base of a Dockerfile in `"build"`, in `devcontainer.json`:

<details><summary>devcontainer.json using pre-built image</summary><pre>{<br/>  "image": "rapidsai/devcontainers:24.02-cpp-llvm16-cuda12.0-nvhpc23.5-ubuntu22.04",<br/>  "hostRequirements": { "gpu": true },<br/>  "workspaceFolder": "/home/coder/${localWorkspaceFolderBasename}",<br/>  "workspaceMount": "source=${localWorkspaceFolder},target=/home/coder/${localWorkspaceFolderBasename},type=bind"<br/>}</pre></details>

### Custom devcontainers

You can also build a custom devcontainer by composing individual features:

<details><summary>devcontainer.json using individual features</summary><pre>{<br/>  "image": "ubuntu:22.04",<br/>  "features": {<br/>    "ghcr.io/rapidsai/devcontainers/features/cmake:24.02": {},<br/>    "ghcr.io/rapidsai/devcontainers/features/ninja:24.02": {},<br/>    "ghcr.io/rapidsai/devcontainers/features/sccache:24.02": {<br/>      "version": "0.5.4"<br/>    }<br/>  },<br/>  "overrideFeatureInstallOrder": [<br/>    "ghcr.io/rapidsai/devcontainers/features/cmake",<br/>    "ghcr.io/rapidsai/devcontainers/features/ninja",<br/>    "ghcr.io/rapidsai/devcontainers/features/sccache"<br/>  ],<br/>  "workspaceFolder": "/home/coder/${localWorkspaceFolderBasename}",<br/>  "workspaceMount": "source=${localWorkspaceFolder},target=/home/coder/${localWorkspaceFolderBasename},type=bind"<br/>}</pre></details>

You can add libraries or programs on top of a pre-built image using this
same mechanism. These are not baked into the image, but cached as a docker
layer.

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
VAULT_S3_TTL=43200

# The URI to the Vault API that generates AWS credentials
# The full URL expands to `$VAULT_HOST/$VAULT_S3_URI?ttl=$VAULT_S3_TTL`
# https://developer.hashicorp.com/vault/api-docs/secret/aws#generate-credentials
VAULT_S3_URI="v1/aws/creds/devs"
```
