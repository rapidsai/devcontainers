# Using the RAPIDS devcontainers

### See the list of `rapidsai/devcontainers` tags [on DockerHub](https://hub.docker.com/r/rapidsai/devcontainers/tags).

We publish a [matrix](matrix.yml) of pre-built images to DockerHub to accelerate initializing local devcontainers, GitHub Codespaces, and CI jobs.

The features that comprise the image are noted in the image tags. If no version is defined for a tool or SDK, the image includes the latest available version at image build time.

> **NOTE:** `git`, `git-lfs`, `github-cli`, `gitlab-cli`, `cmake`, `ninja`, `sccache`, and the devcontainer utility scripts [are included](image/.devcontainer/devcontainer.json#L12-L33) in every pre-built image.

These images can be used as the `"image"`, or as the base of a Dockerfile defined in the `"build"`, in your [`devcontainer.json`](https://containers.dev/implementors/json_reference/#image-specific).
