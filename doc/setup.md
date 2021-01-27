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

#### Editor

If need for debugging and editing, Visual Studio Code is supported. Download here:
https://code.visualstudio.com/download
When installed, go to the "extensions" pane and install the "Remote Development" extension from Microsoft (ms-vscode-remote.vscode-remote-extensionpack).

#### Debug tools

When the docker container is built, the Segger JLink tools are installed. However, debugging using launch configurations is only supported on Linux hosts, since the JLink USB adapter cannot be forwarded to the docker container on Windows hosts. Consequently, in order to debug the target device on a Windows host sytem, the JLink software tools must be installed on the host (if not already installed): https://www.segger.com/downloads/jlink/#J-LinkSoftwareAndDocumentationPack (this approach will also work on Linux hosts).

### Setup environment

The entire build -and debug environment is contained within a docker container. To set it up, the docker container must first be built on the basis of the Dockerfile located in the project root directory. A convenience script is also located here to automate various build processes (only for Linux host and inside the Docker container). To build the container:

Linux:

``` bash
./east.sh --init
```

Alternatively, the container can also be built using VSCode and the installed "Remote Development" extension. Open a terminal in the workspace directory and type:

Linux:

``` bash
source script/.env_vars.sh
code .
```

Windows:

``` ps1
. .\script\.env_vars.ps1
code .
```

Firstly, this will source the environment variables set in the .env_vars file into the current terminal. Secondly, the VSCode editor will be started from within that environment, thereby adopting all of the variables. These are used within various config files by the editor, and it is therefore important that the editor is started this way.

After VSCode has started, open the command palette (press F1) and find "Remote Containers: Reopen in Container". This will build the docker image and can take some time. Additionally, it will also install the VSCode extensions required for intellisense and debug support. When the container has successfully been built, the VSCode editor connects to the VSCode server installed in the docker container.

External (host) terminals can also be attached to a running container, simply call (linux):

``` bash
./east.sh -a
```

from the workspace directory, and a new bash shell will be executed in the container. To build the project, open an integrated terminal from VSCode when the docker container is running and type:

``` bash
./east.sh -b
```

### Debugging

To start debugging, to different approaches exist depending on your host operation system.
For Linux hosts, all tools installed in the docker container can be used, and debugging can simply be started by running the "gdb launch" configuration.
For Windows hosts, the JLinkGDBServer must be started on host by starting the GDB Server application manually (also works on Linux hosts):

Linux:

``` bash
JLinkGDBServer -select USB -device nRF9160_xxAA -if SWD -speed auto -noir
```

Windows:

``` ps1
JLinkGDBServer.exe -select USB -device nRF9160_xxAA -if SWD -speed auto -noir
```

When the server has been started, the debug session can be started from VSCode by running the "gdb attach" configuration.