#!/bin/bash
# script for simplifying project setup, building and debugging
DOCKER_NAME='builder:latest'

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"    # Get path of script
PARENT_PATH="$(dirname "$CURRENT_PATH")"                            # Script parent path

BUILD=false
CLEAN=false
CROSS=true
IN_SUB_DIR=false

# Check for one of the required env variables
if [ "$BOARD" == '' ]; then
    echo "env variables not set, remember to run 'source script/.env_vars' first!"
    exit
fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --init)
    docker build \
        --build-arg UID=$USER_ID \
        --build-arg GID=$GROUP_ID \
        --build-arg PROJ_PATH=$DOCKER_PROJ_PATH \
        -t $DOCKER_NAME .
    exit;;

    -r|--run)
        docker run -ti --rm \
            -v $CURRENT_PATH:$DOCKER_PROJ_PATH \
            -v $NCS_INSTALL_DIR:$DOCKER_PROJ_PATH/ncs \
            -p 5900:5900 \
            $DOCKER_NAME \
            /bin/bash -c "$DOCKER_PROJ_PATH/script/post-start.sh -fe"
    exit;;

    -a|--attach)
    
    docker exec -it \
        $(docker ps -q --filter "ancestor=mcr.microsoft.com/vscode/devcontainers/cpp:ubuntu-20.04") \
        /bin/bash -c "$DOCKER_PROJ_PATH/script/post-start.sh -e"
    exit;;

    -m|--menu)
    west build -t menuconfig
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
    echo "--init: Build docker container"
    echo "-a|--attach: Attach to a running container and spawn a bash shell"
    echo "-r|--run: Run the docker container in the current bash shell"
    echo "-m|--menu: Run menuconfig"
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
