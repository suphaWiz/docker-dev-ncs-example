#!/bin/bash

# Provides environment variables required to build and run the docker container on a Linux host.
# Additionally, environment variables applying for the docker container is also located here:

export NCS_VERSION='v1.4.2'
export BUILD_DIR='build'
export DEFAULT_BOARD=nrf9160dk_nrf9160ns #nrf52840dk_nrf52840
export BOARD=$DEFAULT_BOARD


# NCS_INSTALL_PATH: If empty/default, sdk will be downloaded in the project directory. 
# If a different location for the NCS directory is preferred, the absolute path must be given. 
# The directory will in any case be checked for content and NCS will be downloaded or checked out to the correct
# version when the docker container is started.
NCS_INSTALL_PATH=''
export DOCKER_PROJ_PATH='/work/proj'
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

# Create full ncs install directory path
if  [ "$NCS_INSTALL_PATH" == '' ] || [ "$NCS_INSTALL_PATH" == '.' ]; then
    export NCS_INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/../ncs
else
    export NCS_INSTALL_DIR=$NCS_INSTALL_PATH/ncs # Install/check for NCS in defined directory
fi