# Using devcontainers in projects to provide development environments

This document is aimed at developers who want to use devcontainers to set up
development environments for themselves. It is intended as a general overview
that any project employing devcontainers can link to and avoid duplicating.

For how to add devcontainers to a project, or how to change existing devcontainer
configuration in a project, see [USAGE.md](./USAGE.md).

For how to change the centralized installation and configuration scripts that
are shared among projects, see [DEVELOP.md](./DEVELOP.md).

## System requirements

Devcontainers can be used on Linux, Mac and Windows. They use Docker, so the
system requirements and limitations associated with Docker apply here also. On
Mac and Windows, where a Linux VM must run to support Docker, memory limitations
of that VM may present problems. Otherwise, devcontainers do not add
system requirements beyond the needs of the individual projects being built.
Devcontainers also don't emulate hardware. If a project needs an NVIDIA GPU to
run, then the devcontainer needs to run on a machine with an NVIDIA GPU.
Building is different from running, though, and devcontainers can often be used
to build software that may need a GPU to run.

Devcontainers require Docker. To set that up:

* [Linux - docker engine](https://docs.docker.com/engine/install/)
* [Mac - docker desktop](https://docs.docker.com/desktop/install/mac-install/)
* [Windows](https://docs.docker.com/desktop/install/windows-install/)

Docker Desktop has licensing requirements. NVIDIA employees may [request a
license](https://confluence.nvidia.com/pages/viewpage.action?spaceKey=SWDOCS&title=Requesting+a+Docker+Desktop+License).

### Local vs. Remote Usage

Devcontainers can be used similarly on local machines and on remote machines.
There are no special steps required, but menu options may differ slightly.

## Quickstart

At this point, you have cloned a repo that nominally has some devcontainer
configuration. Devcontainer configuration is stored in a `.devcontainer` folder
in the repository root. The .devcontainer folder will have either a
`devcontainer.json` file, or some number of folders, such as `cuda12.0-conda`
and `cuda12.0-pip`. Where folders are present, each will contain a
`devcontainer.json` file. These files specify how to create and run a container
with a known-good development environment.

### VS Code (Recommended)

Working with devcontainers in VS Code requires an extension: [Remote -
Containers
extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).
When VS Code detects devcontainer.json files, it should prompt you to install
this extension with a pop-up in the lower-right of your VS Code window. If it
doesn't, you'll need to manually install the extension another way.

**Steps**

1. Open the cloned directory in VSCode

2. Launch a Dev Container by clicking the pop-up prompt in the lower right of
the VS Code window that suggests to "Reopen in Container"

   ![Shows "Reopen in Container" prompt when opening the cccl directory in VScode.](./docs-img/reopen_in_container.png)

   - If the pop-up prompt doesn't come up, use the Command Palette to start a Dev Container. Press `[Ctrl|CMD]+Shift+P` to open the Command Palette. Type "Remote-Containers: Reopen in Container" and select it.

     ![Shows "Reopen in Container" in command pallete.](./docs-img/open_in_container_manual.png)

3. Select an environment with the desired build tools from the list:

   ![Shows list of available container environments.](./docs-img/container_list.png)

   The available tools depend on your project. These can be configured when
   generating the matrix of base images. See [the docs on adapting devcontainers](./USAGE.md#custom-devcontainers)
   for more info.

4. VSCode will initialize the selected Dev Container. This can take a few
minutes the first time, as it downloads the base docker image and runs any
specified feature installations. These steps are cached, so subsequent runs are
faster.

5. Once initialized, the local project directory is mounted into the container
to ensure any changes are persistent.

6. You project should now look like any other VS Code project, except that the
blue box in the lower left of the VS Code window should now read `Dev Container
@ <hostname>`. You're done! Any terminal you open will have the build
environment activated appropriately.

7. The devcontainers adds build scripts that fit general usage. Type `build-` and hit
`TAB` to see options for your project. Check the contributing guide in your repo
for further instructions.

**Exiting the devcontainer**

If you are in a VS Code devcontainer on a remote (SSH) machine, you can run
`CTRL|CMD + SHIFT + P` and select `Dev Containers: Reopen in SSH` to return to
your host machine.

### Docker (Manual Approach)

Your project may have its own launch scripts that account for options in
libraries and/or tools. The steps here should work with any repo that uses
devcontainers, but any repo-specific scripts and instructions will probably work
better.

**Prerequisites**

- [Devcontainer CLI ](https://github.com/devcontainers/cli) - needs NodeJS/npm

**Steps**

1. Download the [launch-devcontainer.sh script](./scripts/launch-devcontainer.sh) and
  put it somewhere on PATH. If your project has its own launch script, use it
  here instead.

2. Set your current working directory to the root of your repo containing the
.devcontainer folder

3. Run the launch-container.sh script. Called without arguments, you'll get a menu of containers to choose from:

```
$ ./launch-devcontainer.sh
Using devcontainers in /workspaces/devcontainers.
Select a container (or provide it as a positional argument):
1) cuda11.8-conda
2) cuda11.8-pip
3) cuda12.0-conda
4) cuda12.0-pip
5) main
#?
```

You can also provide devcontainer label (folder name) directly:

```
./launch-devcontainer.sh cuda12.0-conda
```

4. The devcontainer will be built, and you'll be dropped at a shell prompt
inside the container. You're done!

5. The devcontainers adds build scripts that fit general usage. Type `build-`
and hit `TAB` to see options for the project. Check the contributing guide in
your repo for further instructions.


## (Optional) Native build tools - CMake, python builds

The generated scripts mentioned above will take care of running
build tools for you. However, if you need to run the build tools
manually, you can `cd` into your source code folder, which is
mounted as a subfolder in `/home/coder`.

## (Optional) Working with upstream projects

Build scripts are generated only for the main project - the one you have
mounted. Dependencies are automatically downloaded, but these dependencies are
not built locally by default. If you would like to develop other projects in
tandem, you can run their `clone-*` scripts. After they have been cloned,
appropriate `build-*` scripts will be generated. See [the project maintainer
docs on this
topic](./USAGE.md#generating-scripts-for-other-projects-manifestyaml-file).

## (Optional) Authenticate with GitHub for `sccache`

After starting the container with any method, there will be a prompt to
authenticate with GitHub. This grants access to a
[`sccache`](https://github.com/mozilla/sccache) server shared with CI and
greatly accelerates local build times. This is currently limited to NVIDIA
employees belonging to the `NVIDIA` or `rapidsai` GitHub organizations. Assuming
the GitHub authentication here worked, this should work "out of the box" and
should not require any additional AWS credentials for any individual.

Without authentication to the remote server, `sccache` will still accelerate local builds by using a filesystem cache.

Follow the instructions in the prompt as below and enter the one-time code at https://github.com/login/device

  ![Shows authentication with GitHub to access sccache bucket.](./docs-img/github_auth.png)

To manually trigger this authentication, execute the `devcontainer-utils-vault-s3-init` script within the container.

For more information about the sccache configuration and authentication, see [the developer documentation](./DEVELOP.md#build-caching-with-sccache).
