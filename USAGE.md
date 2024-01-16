# Adding and adapting devcontainers to a project

This document describes how to add devcontainers to a project that does not yet
have them, and how you can customize the devcontainer to fit your project's
needs.

For how to use devcontainers to provide development environments, see
[USAGE_IN_PROJECT.md](./USAGE_IN_PROJECT.md)

For how to change the centralized installation and configuration scripts that
are shared among projects, see [DEVELOP.md](./DEVELOP.md).

## Adding devcontainers to a project

Adding devcontainers to a project means adding one or more devcontainer.json
files. You may see scripts in other repos to automate managing multiple
configurations, but fundamentally all you need is at least the one JSON file.
You can bootstrap yourself by copying the folders from
[rapids/devcontainers](./.devcontainer)

Maintaining a matrix of configurations may be easier by following patterns
established by CCCL, or by managing most of the [matrix in the
rapidsai/devcontainers
repo](./matrix.yml)
itself, and then simplifying your actual local devcontainer.json files to be
primarily using a particular base image produced by [the matrix in
rapidsai/devcontainers](./matrix.yml).

## Devcontainers helper scripts

### Generated build scripts

Several scripts are generated for you based on the contents of `manifest.yaml`. By
default, `manifest.yaml` comes from [the RAPIDS/devcontainers
repo](./features/src/rapids-build-utils/opt/rapids-build-utils/manifest.yaml),
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

These are meta-build scripts. They assist with setting up the workspace and
reloading things when important configuration changes happen. You mostly won't
need to worry about these, but it's good to be aware of them. They come from the
[rapidsai/devcontainers
repo](./features/src/rapids-build-utils/opt/rapids-build-utils/bin). These are
described in more detail in [DEVELOP.md](./DEVELOP.md#rapids-build-utils).

### Generating scripts for other projects: `manifest.yaml` file

The build script generation is controlled with a `manifest.yaml` file, which by
default comes from [the rapidsai/devcontainers
repo](./features/src/rapids-build-utils/opt/rapids-build-utils/manifest.yaml)

If you would like to add your project, you can submit a PR to the
rapidsai/devcontainers repo. Before you do that, though, you can test it
locally. Start by copying `manifest.yaml` from the rapidsai/devcontainers repo.
You can put it anywhere, but let's say we put it in .devcontainer/manifest.yaml.

Now open a devcontainer.json file that you want to work with. These will likely
live in a .devcontainer subfolder, such as cuda12.0-pip. In this file, add a
top-level key with this:

```
 "containerEnv": {
   "PROJECT_MANIFEST_YML": "${localWorkspaceFolder}/.devcontainer/manifest.yaml"
 },
```

Rebuild or re-open your devcontainer, and you should now see updated
generated scripts.

## Using the pre-built images

The choice of using a pre-built image refers to the `build/args/BASE` or `image`
entry in `devcontainer.json`. The pre-built images are not meant to be used
directly. We publish a [matrix](matrix.yml) of pre-built images to DockerHub to
accelerate initializing local devcontainers, GitHub Codespaces, and CI jobs.
These use the "feature" scripts to install their components, so you can think of
them as caching those steps.

The features that comprise the image are noted in the image tags. If no version
is defined for a tool or SDK, the image includes the latest available version at
image build time.

> **NOTE:** `git`, `git-lfs`, `github-cli`, `gitlab-cli`, `cmake`, `ninja`, `sccache`, and our devcontainer-utils [are included](image/.devcontainer/devcontainer.json#L12-L33) in each pre-built image.

See the list of `rapidsai/devcontainers` tags [on DockerHub](https://hub.docker.com/r/rapidsai/devcontainers/tags).

### Using in [`devcontainer.json`](https://containers.dev/implementors/json_reference/#image-specific)

The pre-built images can be used as the `"image"`, or as the base of a Dockerfile in `"build"`, in `devcontainer.json`:

<details><summary>devcontainer.json using pre-built image</summary><pre>{<br/>  "image": "rapidsai/devcontainers:24.02-cpp-llvm16-cuda12.0-nvhpc23.5-ubuntu22.04",<br/>  "hostRequirements": { "gpu": true },<br/>  "workspaceFolder": "/home/coder/${localWorkspaceFolderBasename}",<br/>  "workspaceMount": "source=${localWorkspaceFolder},target=/home/coder/${localWorkspaceFolderBasename},type=bind"<br/>}</pre></details>

### Custom devcontainers

You can also build a custom devcontainer by composing individual features:

<details><summary>devcontainer.json using individual features</summary><pre>{<br/>  "image": "ubuntu:22.04",<br/>  "features": {<br/>    "ghcr.io/rapidsai/devcontainers/features/cmake:24.02": {},<br/>    "ghcr.io/rapidsai/devcontainers/features/ninja:24.02": {},<br/>    "ghcr.io/rapidsai/devcontainers/features/sccache:24.02": {<br/>      "version": "0.5.4"<br/>    }<br/>  },<br/>  "overrideFeatureInstallOrder": [<br/>    "ghcr.io/rapidsai/devcontainers/features/cmake",<br/>    "ghcr.io/rapidsai/devcontainers/features/ninja",<br/>    "ghcr.io/rapidsai/devcontainers/features/sccache"<br/>  ],<br/>  "workspaceFolder": "/home/coder/${localWorkspaceFolderBasename}",<br/>  "workspaceMount": "source=${localWorkspaceFolder},target=/home/coder/${localWorkspaceFolderBasename},type=bind"<br/>}</pre></details>

Similarly, any base conatiner can be extended by adding additional features:

<details><summary>devcontainer.json extending base image with additional features</summary><pre>{<br/>  "rapidsai/devcontainers:24.02-cpp-llvm16-cuda12.0-nvhpc23.5-ubuntu22.04",<br/>  "features": {<br/>    "ghcr.io/rapidsai/devcontainers/features/cmake:24.02": {},<br/>    "ghcr.io/rapidsai/devcontainers/features/ninja:24.02": {},<br/>    "ghcr.io/rapidsai/devcontainers/features/sccache:24.02": {<br/>      "version": "0.5.4"<br/>    }<br/>  },<br/>  "overrideFeatureInstallOrder": [<br/>    "ghcr.io/rapidsai/devcontainers/features/cmake",<br/>    "ghcr.io/rapidsai/devcontainers/features/ninja",<br/>    "ghcr.io/rapidsai/devcontainers/features/sccache"<br/>  ],<br/>  "workspaceFolder": "/home/coder/${localWorkspaceFolderBasename}",<br/>  "workspaceMount": "source=${localWorkspaceFolder},target=/home/coder/${localWorkspaceFolderBasename},type=bind"<br/>}</pre></details>

This example is contrived, because base images already all include common build tools such as CMake, ninja and sccache.


> **NOTE:** Feature updates published since your most recent image build will
invalidate your docker image layer cache, meaning it can take the [devcontainers
CLI](https://github.com/devcontainers/cli) longer to initialize containers
composed from individual features.
