# Building Docker containers on Windows

This Dockerfile can be built and then ran while mapped to your workspace to help with building applications on Windows.
This process removes much of the difficulty in assembling a workspace compatible with several CCCL projects.

## Caveats

It is easy to be successful with hyperv enabled, however the true potential of the container can be
achieved when `--isolation=process` is used. This requires either Windows 11 or Server editions of Windows.

## Building the container

### Step 0

If you are developing and testing, [install docker-desktop.](https://docs.docker.com/desktop/) If you are worried about
deployment you may need to
[install Docker Engine](https://docs.docker.com/engine/install/binaries/#install-server-and-client-binaries-on-windows)
manually. Regardless, either option allows you to invoke Docker from the shell is required.

To install Docker Engine via script:

```
## Invoke from within an elevated Powershell prompt
Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1" -o install-docker-ce.ps1
.\install-docker-ce.ps1
## Fetch docker-compose plugin
Invoke-WebRequest -UseBasicParsing "https://github.com/docker/compose/releases/download/v2.18.1/docker-compose-windows-x86_64.exe" -o $Env:ProgramFiles\Docker\docker-compose.exe
```

If issuing docker commands from a non-elevated prompt, you may need to add yourself to the `docker` group or modify the
Docker config: `daemon.json` appropriately to include the group you belong to.

### Step 1

Build desired configuration. Windows 2019 and Windows 2022 versions map to Windows 10 and 11 respectively.

`$> .\scripts\windows\build-windows-image.ps1 -clVersion 14.36 -cudaVersion 12.1 -edition windows-2019 -isolation hyperv -repo local"`

### Step 2

Start up the container and mount workspace directories as needed.

`$> docker run --mount type=bind,src="$(pwd)",dst="C:\thrust" -it local:windows-cuda-12.1-cl-14.36 powershell`

### Step 3 - Build your projects

The environment will be configured to use the compiler you when the image was built, and NVCC will be already available.

`$> cmake -S thrust -B build -G Ninja`
`$> ninja -C build thrust.tests`
