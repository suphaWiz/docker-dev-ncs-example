
# Provides environment variables required to build and run the docker container on a Windows host.
# Additional environment variables that also applies to the docker container is located in the .env_vars.sh.
#  NOTE: if error occur while trying to run the script, such as: ".../.env_vars.ps1 cannot be loaded because running scripts is di
# disabled on this system.", run this command first: "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser"

# Get the location of this script
$INV = (Get-Variable MyInvocation).Value
$DIR_PATH = Split-Path $INV.MyCommand.Path

# NCS_INSTALL_PATH: If empty/default, sdk will be downloaded in the project directory. 
# If a different location for the NCS directory is preferred, the absolute path must be given. 
# The directory will in any case be checked for content and NCS will be downloaded or checked out to the correct
# version when the docker container is started.
$NCS_INSTALL_PATH='.'
$env:DOCKER_PROJ_PATH='/work/proj'
$env:USER_ID=1000
$env:GROUP_ID=1000

# Create full ncs install directory path
if  (!$NCS_INSTALL_PATH -or $NCS_INSTALL_PATH -eq '.') {
    $env:NCS_INSTALL_DIR=$DIR_PATH + '\..\ncs'
} else {
    $env:NCS_INSTALL_DIR=$NCS_INSTALL_PATH + '\ncs' # Install/check for NCS in defined directory
}