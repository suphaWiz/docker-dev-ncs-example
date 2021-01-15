#!/bin/bash
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"    # Get path of script
source $CURRENT_PATH/.env_vars.sh

NCS_PATH=$1

if  [ "$NCS_PATH" == '' ]; then
    echo "Empty ncs path, exiting..."
elif [ "$(ls -A $NCS_PATH)" ]; then
    echo "NCS seems to already be in place. Skipping west init, checking out branch"
    cd $NCS_PATH/nrf
    git checkout $NCS_VERSION
    west update
    # cd $CURRENT_PATH
else
    # Init west which clones the nrfconnect sdk
    west init -m https://github.com/nrfconnect/sdk-nrf --mr $NCS_VERSION $NCS_PATH
    cd $NCS_PATH
    west update
    west zephyr-export
    # cd $CURRENT_PATH
fi