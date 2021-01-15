# NCS_INSTALL_PATH: If empty/default, sdk is downloaded and installed in docker. 
# If set to a different path, west is assumed to be installed on host and tries to download
# and/or change to the chosen NCS_VERSION /home/cylance/devel/sdk
export NCS_INSTALL_PATH=''
export NCS_VERSION='v1.4.1'
export BUILD_DIR='build'
export BOARD=nrf9160dk_nrf9160ns