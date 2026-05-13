# Security Policy

`devcontainers` is the RAPIDS / CCCL / Legate development-container
infrastructure: a set of [Dev Containers Spec](https://containers.dev/)
features under `features/src/` (CUDA, GCC, LLVM, NVHPC, oneAPI, Rust,
sccache, UCX, OpenMPI, ninja, cmake, mambaforge, cccl-dev, gitlab-cli,
rapids-build-utils, utils), a base image published as
`rapidsai/devcontainers` on DockerHub, and reference `devcontainer.json`
configs under `.devcontainer/` for the common CUDA × package-manager
matrices.

Because developers use these images on their workstations — mounting host
credentials and sibling source repositories into the running container,
running build tools from the image with whatever permissions the host
grants Docker — the security posture is dominated by what the features
download at build time and by what trust the host extends to a running
devcontainer.

## Reporting a Vulnerability

Please report security vulnerabilities privately through one of the channels
below. **Do not open a public GitHub issue, PR, or discussion** for a
suspected vulnerability.

1. **NVIDIA Vulnerability Disclosure Program (preferred)**
   <https://www.nvidia.com/en-us/security/>
   Submit through the NVIDIA PSIRT web form. This is the fastest path to
   triage and tracking.

2. **Email NVIDIA PSIRT**
   psirt@nvidia.com — encrypt sensitive reports with the
   [NVIDIA PSIRT PGP key](https://www.nvidia.com/en-us/security/pgp-key).

3. **GitHub Private Vulnerability Reporting**
   Use the **Security** tab on this repository → *Report a vulnerability*.

Please include, where possible:

- Affected component (a specific feature under `features/src/`, a base
  image tag on DockerHub, a `.devcontainer/` reference config, a Windows
  helper script)
- Whether the issue is in this repo, in how a consumer project references
  these features, or in the host trust model a devcontainer assumes
- Reproduction steps, including the feature configuration, the base image
  tag, and the host's mount configuration
- Impact assessment (host credential exposure, supply-chain compromise
  of a feature install, image-distribution tampering, CI/CD weakness)
- Any relevant CWE / CVE identifiers

NVIDIA PSIRT will acknowledge receipt and coordinate triage, fix
development, and coordinated disclosure. More on NVIDIA's response
process: <https://www.nvidia.com/en-us/security/psirt-policies/>.

## Security Architecture & Context

**Classification:** Container image build + Dev Containers Spec feature
library. The repository contains feature definitions, Dockerfiles, build
helpers, and GitHub Actions workflows that produce and publish the
`rapidsai/devcontainers` image family.

**Shipped artifacts and consumed entrypoints:**

- **`rapidsai/devcontainers` DockerHub images** — base images consumed
  via tags like `rapidsai/devcontainers:26.06-cpp-mambaforge`. Tags
  are reused as new patches are published.
- **`features/src/*/`** — Dev Containers Spec features. Each feature has
  an `install.sh` that runs at image-build time inside the build
  container, and (often) a `.bashrc` snippet appended to the resulting
  shell environment.
- **`.devcontainer/cuda<ver>-{conda,pip}/devcontainer.json`** —
  reference devcontainer configs for the common CUDA × package-manager
  combinations consumer repositories adopt.
- **`windows/` and `*.ps1` helpers** (24 PowerShell scripts) —
  Windows-side launchers for Codespaces / WSL2 / Docker Desktop flows.
- **`.github/workflows/`** — image build, publish, and matrix
  generation workflows.

**Host trust posture established by the reference configs:**

The reference `devcontainer.json` files (e.g.
`.devcontainer/cuda13.0-conda/devcontainer.json`) mount the following
host paths into the container by default:

- The current workspace + every expected sibling RAPIDS source repo
  (`rmm`, `cudf`, `cuml`, `cugraph`, `kvikio`, `ucxx`, `raft`, `cuvs`,
  `dask-cuda`, `rapidsmpf`, `nvforest`, `cugraph-gnn`, `nx-cugraph`,
  `cuopt`) under `/home/coder/<repo>`.
- `~/../.aws`, `~/../.cache`, `~/../.config`, `~/../.conda/pkgs`, and
  per-CUDA `~/../.conda/envs`.

Anything inside the container at `/home/coder/.aws` is the host's
`.aws` directory; cloud credentials, browser caches, dotfiles, and
the developer's sibling source trees are all reachable from the
container. The `main` devcontainer additionally sets
`"containerUser": "root"`, so post-attach code runs as root inside
the container.

**Out of scope for this policy:** vulnerabilities in upstream base
images (`ubuntu:22.04`, `condaforge/miniforge3`, `nvidia/cuda`), in
Docker / Docker Desktop, in the Dev Containers Spec implementations
(`devcontainer-cli`, VS Code's `ms-vscode-remote.remote-containers`,
Codespaces), in DockerHub itself, or in the upstream projects that
features install (CUDA Toolkit, sccache, LLVM, GCC, NVHPC, oneAPI,
Rust, UCX, OpenMPI, mambaforge). Vulnerabilities in *how* this repo
fetches, configures, or composes those upstreams — feature install
scripts, mount defaults, container user, CI workflows — are in scope.

## Threat Model

The threats below trace to specific components and patterns in this
repository. Several were remediated through the
[RAPIDS Security Audit](https://github.com/orgs/rapidsai/projects/207)
(template injection, mutable workflow refs, missing permissions blocks).

1. **Devcontainers inherit broad host trust.**
   The reference `devcontainer.json` configs mount the host's
   `~/.aws`, `~/.config`, `~/.cache`, every sibling source repository,
   and the user's conda environment cache into the running container.
   Any process inside the container — including features installed at
   build time and scripts the developer subsequently runs — can read
   AWS credentials, GitHub tokens that live in `.config`, SSH
   configuration, browser data co-located in `.cache`, and the
   source of every sibling RAPIDS project. A malicious feature
   install script, a compromised tool installed by a feature, or a
   carelessly invoked command in a normal dev session can exfiltrate
   any of those.

2. **`containerUser: root` in the main devcontainer.**
   The base `image/.devcontainer/devcontainer.json` declares
   `"containerUser": "root"`. Code running as root inside the
   container can write to mounted host paths with uid 0 ownership,
   which surprises subsequent host-side tooling and (depending on
   Docker rootless / rootful configuration) can produce files the
   host user cannot remove without `sudo`. Consumer configs that
   override this should be reviewed against their feature set.

3. **Feature install scripts fetch binaries without uniform
   integrity verification.**
   Feature install scripts under `features/src/*/install.sh`
   download upstream binaries — sccache, ninja, cmake, gcc, llvm,
   nvhpc, oneapi, rust, ucx — over HTTPS at image-build time. Some
   features verify checksums or use package managers with their own
   verification; others (notably `sccache`, which `wget | tar`s the
   release tarball) do not. A compromised upstream release asset, or
   in-path tampering on the image-build host, can substitute the
   binary that subsequently runs as the developer.

4. **Mutable image tags on DockerHub.**
   Consumers reference base images by tag (e.g.
   `rapidsai/devcontainers:26.06-cpp-mambaforge`). Tags are
   reused as new patches are published, so two builds of the same
   consumer project on different days can produce different images.
   This is a usability choice, not a bug, but production-grade
   reproducibility requires pinning to a digest
   (`rapidsai/devcontainers@sha256:…`).

5. **`devcontainers/features` ecosystem inheritance.**
   Reference configs depend on features published at
   `ghcr.io/devcontainers/features/*` (common-utils, git, git-lfs,
   github-cli, etc.). Those features are referenced by tag
   (`:2`, `:1.3.2`, `:1.2.1`, `:1.0.12`) rather than digest. A
   compromise of any of those upstream feature publishers becomes
   a compromise of every devcontainer that consumes them.

6. **GitHub Actions template injection.**
   Workflows in `.github/workflows/` historically interpolated
   `${{ ... }}` values into shell `run:` blocks at evaluation time,
   including values derivable from PR metadata. The audit remediated
   specific instances; the risk class recurs on new workflow
   contributions and on changes that route untrusted strings into
   shell context.

7. **Mutable references to external workflows and actions.**
   Reusable workflows or third-party actions referenced by tag
   rather than commit SHA let upstream maintainers retroactively
   change the code that runs here. The audit produced SHA-pin
   fixes; re-introduction on new contributions is the recurring
   risk.

8. **Missing top-level `permissions:` blocks.**
   Workflows without an explicit top-level `permissions:` block
   receive a broader default `GITHUB_TOKEN` scope than most jobs
   need. The audit remediated specific workflows; new workflows
   should declare a minimal top-level `permissions:` block and only
   grant per-job elevations where required.

9. **Windows-side PowerShell helpers.**
   The `windows/` directory and `*.ps1` scripts execute on
   developer workstations to bootstrap Docker Desktop / WSL2
   integrations. Variables interpolated into shell context, paths
   pulled from the registry, and `Invoke-WebRequest` to remote
   resources are common PowerShell pitfalls; new helpers should
   be reviewed with that lens.

## Critical Security Assumptions

The following are assumed of developers using these devcontainers and
of operators publishing the base images. These are load-bearing —
violating them turns documented behavior into a vulnerability.

- **Developers trust the features they install.**
  A feature's `install.sh` runs at image-build time with the
  privileges of the build context. Features can fetch binaries,
  modify the shell environment, and read whatever the build context
  exposes. Adding a custom or third-party feature is equivalent to
  installing a build-time dependency from that source; treat it as
  such.

- **Mounted host paths are an extension of the host.**
  Anything mounted into the container retains host-side identity
  on disk (subject to Docker's user namespace configuration). Files
  written by container processes appear in `~/.aws`, `~/.config`,
  and sibling source repos on the host. The container is not a
  sandbox for protecting host secrets.

- **The base image tag is pinned to a digest in production-like
  flows.**
  Tags such as `rapidsai/devcontainers:26.06-cpp-mambaforge` are
  reused. Consumers who need reproducibility — and who want the
  image they pull today to match the image they tested yesterday —
  should pin to digests (`@sha256:…`).

- **Feature install scripts are reviewed before adoption.**
  New features added to this repository, and new features adopted
  in consumer `.devcontainer/` configs, must be reviewed for what
  they download, where from, and whether they verify integrity.
  The `wget | tar` pattern is fine for trusted sources at known
  releases; it is not fine for paths an attacker can influence.

- **Reference `devcontainer.json` configs are starting points, not
  prescriptions.**
  Consumers that need a tighter trust posture (e.g. CI environments
  that should not have host AWS credentials available, regulated
  workloads) should adapt the reference configs — removing mounts
  of `.aws` / `.config` / `.cache`, switching `containerUser` to a
  non-root user, scoping sibling-repo mounts to what they actually
  need.

- **Workflow `run:` blocks consume inputs via `env:`.**
  Any value that originates from PR metadata or other
  attacker-influenced context must reach a `run:` block through an
  `env:` mapping, not via direct `${{ ... }}` interpolation.

- **Workflows pin third-party actions by commit SHA, and use minimal
  `permissions:`.**
  GitHub's default `GITHUB_TOKEN` permissions are broader than most
  jobs need; this repo's workflows should declare a minimal top-level
  `permissions:` block. Third-party actions should be pinned by
  commit SHA rather than tag.

- **Codespaces and shared dev environments do not pool credentials
  across users.**
  When devcontainers are run in shared infrastructure (Codespaces,
  team-shared VMs, browser-based IDEs), operators must ensure that
  credentials mounted into one user's devcontainer are not reachable
  from another user's session.

## Supported Versions

Image tags follow the RAPIDS release cadence. Older image tags are not
re-published with new security fixes; pull a recent tag (or rebuild
from a recent `RAPIDS_VERSION`) to receive upstream and in-house
security updates. Feature definitions follow a rolling-`main` model
with periodic tagged releases; consumers should pin to commit SHAs.

## Dependency Security

devcontainers depends on the security posture of its base images
(`ubuntu:22.04`, the NVIDIA CUDA images, `condaforge/miniforge3`), the
upstream tools each feature installs (CUDA Toolkit, sccache, LLVM,
GCC, NVHPC, oneAPI, Rust, UCX, OpenMPI, mambaforge), the
`ghcr.io/devcontainers/features/*` features it consumes, and the Dev
Containers Spec implementations consumers run. Upstream CVE-driven
updates may require image rebuilds and feature version bumps;
high-severity advisories may trigger out-of-band republishes.
