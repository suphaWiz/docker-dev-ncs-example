#!/bin/bash

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"    # Get path of script
source $CURRENT_PATH/.env_vars.sh

CMD=$1

# Check for and init west if neccessary
if [ "$(ls -A $NCS_INSTALL_DIR)" ] && [[ $CMD != *"f"* ]]; then
    echo "NCS seems to already be in place. Skipping west init"
    # cd $NCS_INSTALL_DIR/nrf
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