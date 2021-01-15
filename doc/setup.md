# Howto

## Project setup

### Install Git

Debian/Ubuntu:

``` bash
    sudo apt install git
```

Windows:
https://git-scm.com/download/win

### Clone repo to local directory

``` bash
    git clone repo.git
```

### Install dependencies

Debian/Ubuntu:

``` bash
    ./script/install-requirements.sh
```

Windows:
https://docs.docker.com/docker-for-windows/install/

### Editor

If need for debugging and editing, Visual Studio Code is supported. Download here:
https://code.visualstudio.com/download
When installed, go to the "extensions" pane and install the "Remote Development" extension from Microsoft (ms-vscode-remote.vscode-remote-extensionpack).

### Setup environment

The entire build -and debug environment is contained within a docker container. To set it up, the docker container must first be built on the basis of the Dockerfile located in the project root directory. A convenience script is also located here to automate various build processes (only for Linux host and inside the Docker container). To build the container:

Linux:
``` bash
./east.sh --init
```

Alternatively, the container can also be built using VS Code and the installed "Remote Development" extension: Open the command palette (press F1) and find "Remote Containers: Reopen in Container". This will run the same Dockerfile as the builder script. Additionally, it will also install the VS Code extensions required for intellisense and debug support. When the docker has successfully been built, it the extensions automatically starts it and connects the VS Code editor to the contained environment.