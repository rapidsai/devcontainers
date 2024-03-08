# Adding and adapting devcontainers to a project

This document describes how to add devcontainers to a project that does not yet
have them and how to customize the devcontainer to fit a project's
needs.

For how to use devcontainers to provide development environments, see
[USAGE_IN_PROJECT.md](./USAGE_IN_PROJECT.md)

For how to change the centralized installation and configuration scripts that
are shared among projects, see [DEVELOP.md](./DEVELOP.md).

## Adding devcontainers to a project

Adding devcontainers to a project means adding one or more `devcontainer.json`
files. One devcontainer is equivalent to one `devcontainer.json` file. Projects
such as [CCCL](https://github.com/NVIDIA/cccl/blob/main/.devcontainer/README.md)
have additional scripts that manage many configurations. New projects needing
only cuda and python can bootstrap themselves by copying the `cuda-*` folders
from [rapids/devcontainers](./.devcontainer).

## Devcontainers helper scripts

### Generated build scripts

Several scripts are generated based on the contents of `manifest.yaml`. By
default, `manifest.yaml` comes from [the RAPIDS/devcontainers
repo](./features/src/rapids-build-utils/opt/rapids-build-utils/manifest.yaml),
but [a local `manifest.yaml` file can be used instead](#generating-scripts-for-other-projects-manifestyaml-file).

The generated scripts are:
* `/usr/bin/build-*`
* `/usr/bin/clean-*`
* `/usr/bin/clone-*`
* `/usr/bin/configure-*`

Here the `*` is a placeholder for the project name and the kind of
build. For example, a project with a python component in `manifest.yaml`
will have `build-cudf-python`.

These scripts may trigger side-effects. For example, `build-*` scripts are only
generated for projects that exist in the workspace. When working on `cudf`,
which depends on `rmm`, the default workspace only mounts `cudf` and generates
`build-cudf` scripts. To obtain `rmm` build scripts also, run `clone-rmm`,
which will clone `rmm` into the workspace and generate build scripts for it.

### rapids-build-utils

[`rapids-build-utils`](./features/src/rapids-build-utils/opt/rapids-build-utils/bin)
scripts are meta-build scripts. They assist with setting up the workspace and
reloading things when important configuration changes happen.
`rapids-build-utils` scripts are most often called indirectly by devcontainer
lifecycle hooks, but are also useful for forcing updates in the workspace.
`rapids-build-utils` scripts are described in more detail in
[DEVELOP.md](./DEVELOP.md#rapids-build-utils).

### Generating scripts for other projects: `manifest.yaml` file

Build script generation is controlled with a `manifest.yaml` file. This file
comes from [the rapidsai/devcontainers
repo](./features/src/rapids-build-utils/opt/rapids-build-utils/manifest.yaml),
but can be [overridden with a local manifest.yaml file](#local-changes).  New
projects and changes to dependencies can be submitted in a PR to the
[rapidsai/devcontainers](https://github.com/rapidsai/devcontainers) repo.

> **NOTE** manifest.yaml's content is pinned in
`.devcontainer/*/devcontainer.json` indirectly via the pin on rapids-build-utils.
For changes in manifest.yaml to be reflected in the devcontainer, the manifest.yaml
changes need to be present in a release of `rapidsai/devcontainers`, and the pin
on `rapids-build-utils` must be updated in the project's devcontainer.json file(s).

```
  "features": {
     "ghcr.io/rapidsai/devcontainers/features/rapids-build-utils:24.2": {}
  },
```

In this `devcontainer.json` excerpt, the `24.2` value is the pin that would need
to be updated.

#### Local changes

To work around the delay in getting a change merged into the devcontainers repo
and have a new tag in place, a local manifest.yaml file can be used. Start by
copying `manifest.yaml` from the rapidsai/devcontainers repo.  This file can
live anywhere, but this example has it in `.devcontainer/manifest.yaml`.

In the desired devcontainer.json file, add a top-level key with this:

```
 "containerEnv": {
   "PROJECT_MANIFEST_YML": "/home/coder/${localWorkspaceFolderBasename}/.devcontainer/manifest.yaml"
 },
```

Rebuild or re-open the devcontainer, and the scripts (`build-*`, `clone-*`,
etc.) will be regenerated using the local `.devcontainer/manifest.yaml` instead
of the manifest.yaml that comes from the devcontainer.json-pinned
`rapids-build-utils` version.   The `rapids-generate-scripts` command from
[rapids-build-utils](./features/src/rapids-build-utils/opt/rapids-build-utils/bin)
will also force a refresh of these scripts without rebuilding the devcontainer.

## Using the pre-built images

The choice of using a pre-built image refers to the `build/args/BASE` or `image`
entry in `devcontainer.json`. The pre-built images are not meant to be used
directly. We publish a [matrix](matrix.yml) of pre-built images to DockerHub to
accelerate initializing local devcontainers, GitHub Codespaces, and CI jobs.
These use the "feature" scripts to install their components, so these base
containers effectively cache running their feature scripts.

The features that comprise the image are noted in the image tags. If no version
is defined for a tool or SDK, the image includes the latest available version at
image build time.

> **NOTE:** `git`, `git-lfs`, `github-cli`, `gitlab-cli`, `cmake`, `ninja`, `sccache`, and [devcontainer-utils](./features/src/utils) [are included](image/.devcontainer/devcontainer.json#L12-L33) in each pre-built image.

See the list of `rapidsai/devcontainers` tags [on DockerHub](https://hub.docker.com/r/rapidsai/devcontainers/tags).

### Using in [`devcontainer.json`](https://containers.dev/implementors/json_reference/#image-specific)

The pre-built images can be used as the `"image"`, or as the base of a Dockerfile in `"build"`, in `devcontainer.json`:

<details><summary>devcontainer.json using pre-built image</summary><pre>{<br/>  "image": "rapidsai/devcontainers:24.02-cpp-llvm16-cuda12.0-nvhpc23.5-ubuntu22.04",<br/>  "hostRequirements": { "gpu": true },<br/>  "workspaceFolder": "/home/coder/${localWorkspaceFolderBasename}",<br/>  "workspaceMount": "source=${localWorkspaceFolder},target=/home/coder/${localWorkspaceFolderBasename},type=bind"<br/>}</pre></details>

### Custom devcontainers

Custom devcontainers can be specified by composing individual features:

<details><summary>devcontainer.json using individual features</summary><pre>{<br/>  "image": "ubuntu:22.04",<br/>  "features": {<br/>    "ghcr.io/rapidsai/devcontainers/features/cmake:24.02": {},<br/>    "ghcr.io/rapidsai/devcontainers/features/ninja:24.02": {},<br/>    "ghcr.io/rapidsai/devcontainers/features/sccache:24.02": {<br/>      "version": "0.5.4"<br/>    }<br/>  },<br/>  "overrideFeatureInstallOrder": [<br/>    "ghcr.io/rapidsai/devcontainers/features/cmake",<br/>    "ghcr.io/rapidsai/devcontainers/features/ninja",<br/>    "ghcr.io/rapidsai/devcontainers/features/sccache"<br/>  ],<br/>  "workspaceFolder": "/home/coder/${localWorkspaceFolderBasename}",<br/>  "workspaceMount": "source=${localWorkspaceFolder},target=/home/coder/${localWorkspaceFolderBasename},type=bind"<br/>}</pre></details>

Similarly, any base conatiner can be extended by adding additional features:

<details><summary>devcontainer.json extending base image with additional features</summary><pre>{<br/>  "rapidsai/devcontainers:24.02-cpp-llvm16-cuda12.0-nvhpc23.5-ubuntu22.04",<br/>  "features": {<br/>    "ghcr.io/rapidsai/devcontainers/features/cmake:24.02": {},<br/>    "ghcr.io/rapidsai/devcontainers/features/ninja:24.02": {},<br/>    "ghcr.io/rapidsai/devcontainers/features/sccache:24.02": {<br/>      "version": "0.5.4"<br/>    }<br/>  },<br/>  "overrideFeatureInstallOrder": [<br/>    "ghcr.io/rapidsai/devcontainers/features/cmake",<br/>    "ghcr.io/rapidsai/devcontainers/features/ninja",<br/>    "ghcr.io/rapidsai/devcontainers/features/sccache"<br/>  ],<br/>  "workspaceFolder": "/home/coder/${localWorkspaceFolderBasename}",<br/>  "workspaceMount": "source=${localWorkspaceFolder},target=/home/coder/${localWorkspaceFolderBasename},type=bind"<br/>}</pre></details>

This example is contrived, because base images already all include common build tools such as CMake, ninja and sccache.


> **NOTE:** Feature updates published since the most recent image build will
invalidate the docker image layer cache, meaning it can take the [devcontainers
CLI](https://github.com/devcontainers/cli) longer to initialize containers
composed from individual features.
