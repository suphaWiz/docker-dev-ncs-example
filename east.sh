#!/bin/bash
# script for simplifying project setup, building and debugging
DOCKER_NAME='builder:latest'
DEFAULT_NCS_DIR='ncs'

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"    # Get path of script
PARENT_PATH="$(dirname "$CURRENT_PATH")"                            # Script parent path
NCS_PATH=''

DOCKER_MANAGE_NCS=false
BUILD=false
CLEAN=false
CROSS=true
IN_SUB_DIR=false
source $CURRENT_PATH/script/.env_vars.sh
source ~/.bashrc

# Set NCS_PATH variable
if  [ "$NCS_INSTALL_PATH" == '' ]; then         # Let docker install NCS
    DOCKER_MANAGE_NCS=true
elif [ "$NCS_INSTALL_PATH" == '.' ]; then       # Install NCS in current directory
    NCS_PATH=$CURRENT_PATH/$DEFAULT_NCS_DIR
else
    NCS_PATH=$NCS_INSTALL_PATH/$DEFAULT_NCS_DIR # Install/check for NCS in derfined directory
fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --init)

    docker build --build-arg UID=1001 --build-arg GID=1001 --build-arg NCS_IN_DOCKER=$DOCKER_MANAGE_NCS -t $DOCKER_NAME .
    
    if [ DOCKER_MANAGE_NCS == false ]; then
        ./script/ncs-init.sh $NCS_PATH
        cd $CURRENT_PATH
    fi
    # --build-arg UID=$(id -u) --build-arg GID=$(id -g)
    
    exit;;

    -r|--run)
    if [ DOCKER_MANAGE_NCS == true ]; then
        docker run \ 
            -ti \
            --rm \
            --privileged \
            --cap-add=SYS_PTRACE \
		    --security-opt \
		    seccomp=unconfined \
            -v /dev/bus/usb:/dev/bus/usb \
            -v $CURRENT_PATH:/proj/fw \
            -v $NCS_PATH:/proj/ncs \
            $DOCKER_NAME
    else
        docker run \
            -ti \
            --rm \
            --privileged \
            --cap-add=SYS_PTRACE \
		    --security-opt \
		    seccomp=unconfined \
            -v /dev/bus/usb:/dev/bus/usb \
            -v $CURRENT_PATH:/proj \
            -v $NCS_PATH:/proj/ncs \
            $DOCKER_NAME
    fi
    exit;;

    -a|--attach)
    
    docker exec -it \
        $(docker ps -q --filter ancestor=mcr.microsoft.com/vscode/devcontainers/cpp:ubuntu-20.04) \
        /bin/bash
    exit;;

    -b|--build)
    cd $CURRENT_PATH
    west build -b $BOARD -d $BUILD_DIR
    exit;;

    -c|--clean)
    echo "Cleaning directory \"$BUILD_DIR\""
    cd $CURRENT_PATH
    rm -rf $BUILD_DIR
    exit;;
    
    -t|--term)
    screen -fn /dev/ttyACM0 115200
    exit;;

    -h|--help|*)
    echo "Options:"
    echo "--init: Build docker, and install ncs if set:$DOCKER_MANAGE_NCS"
    echo "-a|--attach: Attach to a running container and spawn bash"
    echo "-r|--run: Run the docker container in the current bash"
    echo "-b|--build: Build the project for the configured board: $BOARD"
    echo "-c|--clean: Clean the current build directory"
    echo "-t|--term: Create a terminal session using screen. Exit: (Ctrl+a, d)"
    exit;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters
