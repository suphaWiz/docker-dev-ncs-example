#!/bin/bash
# script for simplifying project setup, building and debugging
DOCKER_NAME='builder:latest'

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"    # Get path of script
PARENT_PATH="$(dirname "$CURRENT_PATH")"                            # Script parent path
WSL=false

function check_return {
    "$@"
    local status=$?
    if (( status != 0 )); then
        # echo "error with $1" >&2
        exit
    fi
    return $status
}

# Check for one of the required env variables
if [ "$BOARD" == '' ]; then
    echo "env variables not set, remember to run 'source script/.env_vars.sh' first!"
    exit
fi

# Identify if using WSL
set -e
if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null ; then
   WSL=true
fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --setup)
    mkdir ncs >/dev/null 2>&1
    docker build \
        --build-arg UID=$USER_ID \
        --build-arg GID=$GROUP_ID \
        --build-arg PROJ_PATH=$DOCKER_PROJ_PATH \
        -t $DOCKER_NAME .
    shift;;

    -r|--run)
        docker run -ti --rm \
            -v $CURRENT_PATH:$DOCKER_PROJ_PATH \
            -v $NCS_INSTALL_DIR:$DOCKER_PROJ_PATH/ncs \
            # -p 5900:5900 \
            $DOCKER_NAME \
            /bin/bash -c "$DOCKER_PROJ_PATH/script/post-start.sh -fe"
    exit;;

    -a|--attach)
    if [ "$WSL" == true ]; then # Currently only filtering on status if WSL since ancestor filter does not seem to work
    docker exec -it \
        $(docker ps -q --filter "status=running") \
        /bin/bash -c "$DOCKER_PROJ_PATH/script/post-start.sh -e"
    else
    docker exec -it \
        $(docker ps -q --filter "ancestor=mcr.microsoft.com/vscode/devcontainers/cpp:ubuntu-20.04") \
        /bin/bash -c "$DOCKER_PROJ_PATH/script/post-start.sh -e"
    fi
    exit;;
    
    -i|--init)
    cd $CURRENT_PATH
    check_return cmake -B $BUILD_DIR/app -GNinja -DBOARD=$BOARD -DBOARD_ROOT=. .
    check_return cmake -B $BUILD_DIR/gtest -GNinja -DBOARD=native_posix -DCONF_FILE=../prj_native_posix.conf tests
    check_return cmake -B $BUILD_DIR/qemu -GNinja -DBOARD=qemu_x86 -DCONF_FILE=qemu_x86.conf .
    exit;;

    -m|--menu)
    west build -t menuconfig -d $BUILD_DIR/app
    exit;;

    -b|--build)
    cd $CURRENT_PATH
    ninja -C $BUILD_DIR/app
    exit;;

    -q|--qemu)
    cd $CURRENT_PATH
    check_return ninja -C $BUILD_DIR/qemu
    ninja run -C $BUILD_DIR/qemu
    exit;;

    -t|--test)
    cd $CURRENT_PATH
    check_return ninja -C $BUILD_DIR/gtest
    ninja run -C $BUILD_DIR/gtest
    exit;;

    -c|--clean)
    echo "Cleaning directory \"$BUILD_DIR\""
    cd $CURRENT_PATH
    rm -rf $BUILD_DIR
    shift;;
    
    --term)
    screen -fn /dev/ttyACM0 115200
    exit;;

    -d|--debug)
    if [ "$WSL" == true ]; then
    JLinkGDBServerCL.exe -select USB -device nRF9160_xxAA -if SWD -speed auto -noir
    else
    JLinkGDBServer -select USB -device nRF9160_xxAA -if SWD -speed auto -noir
    fi
    exit;;

    -u|--update)
    west update
    exit;;

    -h|--help|*)
    echo "Options:"
    echo "--setup: Build/setup docker container (host)"
    echo "-r|--run: Run the docker container in the current bash shell (host)"
    echo "-a|--attach: Attach to a running container and spawn a bash shell (host)"
    echo "--term: Create a terminal session using screen. Exit: (Ctrl+a, d) (host)"
    echo "-d|--debug: Start GDB server and attach to target (any)"
    echo "--update: Run west update and checkout potential changes in config (docker)"
    echo "-i|--init: Run/re-run cmake and initialize the build directories"
    echo "-m|--menu: Run menuconfig for app (docker)"
    echo "-b|--build: Build application for the configured board: $BOARD (docker)"
    echo "-q|--qemu: Build and run application for qemu target (docker)"
    echo "-t|--test: Build and run unit tests (docker)"
    echo "-c|--clean: Clean the current build directory (docker)"
    exit;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters
