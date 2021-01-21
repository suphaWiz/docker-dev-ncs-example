#!/bin/bash

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"    # Get path of script
source $CURRENT_PATH/.env_vars

CMD=$1

# echo "Checking for NCS in $NCS_INSTALL_PATH"

# Check for and init west if neccessary
if  [ "$NCS_INSTALL_PATH" == '' ]; then
    echo "Empty NCS path, exiting..."
elif [ "$(ls -A $NCS_INSTALL_PATH)" ] && [[ $CMD != *"f"* ]]; then
    echo "NCS seems to already be in place. Skipping west init"
    # cd $NCS_INSTALL_PATH/nrf
    # git checkout $NCS_VERSION
    # cd /
    # west update
else
    # Init west which clones the nrfconnect sdk
    echo "Running west init"
    west init -l $PROJ_PATH
    west update
    west zephyr-export
    # cd $CURRENT_PATH
fi

if [[ $CMD == *"e"* ]]; then
    exec /bin/bash --init-file $CURRENT_PATH/bash-init.sh
else
    $CURRENT_PATH/bash-init.sh
fi