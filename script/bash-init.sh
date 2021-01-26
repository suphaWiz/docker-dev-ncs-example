#!/bin/bash

CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"    # Get path of script

source $CURRENT_PATH/.env_vars # Source the env_vars into the bash shell

# Set options for bash shell
set +o noclobber
