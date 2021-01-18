FROM mcr.microsoft.com/vscode/devcontainers/cpp:ubuntu-20.04

ARG TOOLCHAIN_VARIANT=gnuarmemb
ARG UID=1001
ARG GID=1001
ARG NCS_IN_DOCKER=false

ENV ZSDK_VERSION=0.11.4
ENV GCC_ARM_NAME=gcc-arm-none-eabi-10-2020-q4-major
ENV CMAKE_VERSION=3.18.3
ENV RENODE_VERSION=1.11.0
ENV NRF_TOOLS_VERSION=10121
ENV TZ=Europe/Berlin

RUN groupadd -g $GID -o user
RUN useradd -u $UID -m -g user -G plugdev user \
    && echo 'user ALL = NOPASSWD: ALL' > /etc/sudoers.d/user \
    && chmod 0440 /etc/sudoers.d/user
RUN chown -R user:user /home/user

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Download dependencies using wget
RUN wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://www.nordicsemi.com/-/media/Software-and-other-downloads/Desktop-software/nRF-command-line-tools/sw/Versions-10-x-x/10-12-1/nRFCommandLineTools10121Linuxamd64tar.gz && \
    wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/${GCC_ARM_NAME}-x86_64-linux.tar.bz2  && \
    wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
    wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate --post-data 'accept_license_agreement=accepted&non_emb_ctr=confirmed&submit=Download+software' https://www.segger.com/downloads/jlink/JLink_Linux_x86_64.tgz
# wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/zephyr-sdk-${ZSDK_VERSION}-setup.run && \
# wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://github.com/renode/renode/releases/download/v${RENODE_VERSION}/renode_${RENODE_VERSION}_amd64.deb && \

# Extract archives
RUN chmod +x cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
    ./cmake-${CMAKE_VERSION}-Linux-x86_64.sh --skip-license --prefix=/usr/local && \
    rm -f ./cmake-${CMAKE_VERSION}-Linux-x86_64.sh

RUN mkdir -p /opt/tools/temp
RUN tar -xf nRFCommandLineTools10121Linuxamd64tar.gz -C /opt/tools/temp && \
    tar -xf opt/tools/temp/nRF-Command-Line-Tools_10_12_1.tar -C /opt/tools/ && \
    rm -f nRF-Command-Line-Tools_10_12_1_Linux-amd64.tar.gz && \
    rm -rf /opt/tools/temp

RUN mkdir -p /opt/SEGGER/JLink
RUN tar -xf JLink_Linux_x86_64.tgz --strip-components=1 -C /opt/SEGGER/JLink/ && \
    rm -f JLink_Linux_x86_64.tgz

RUN mkdir -p /opt/toolchains
RUN tar -xf ${GCC_ARM_NAME}-x86_64-linux.tar.bz2 -C /opt/toolchains/ && \
    rm -f ${GCC_ARM_NAME}-x86_64-linux.tar.bz2

# RUN sh "zephyr-sdk-${ZSDK_VERSION}-setup.run" --quiet -- -d /opt/toolchains/zephyr-sdk-${ZSDK_VERSION} && \
#     rm "zephyr-sdk-${ZSDK_VERSION}-setup.run"

# Download dependencies using apt
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt -y update && \
    apt -y upgrade && \
    apt install --no-install-recommends -y \
    wget \
    build-essential \
    ccache \
    device-tree-compiler \
    dfu-util \
    g++ \
    gcc \
    gcc-multilib \
    make \
    ninja-build \
    # python3-dev \
    python3-pip \
    # python3-ply \
    # python3-setuptools \
    # python-xdg \
    locales \
    git \
    sudo \
    libncurses5 \
    screen
# apt install -y ./renode_${RENODE_VERSION}_amd64.deb && \
# rm renode_${RENODE_VERSION}_amd64.deb && \
# rm -rf /var/lib/apt/lists/*

# Download dependencies using pip
RUN pip3 install wheel &&\
    pip3 install -r https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements.txt && \
    pip3 install -r https://raw.githubusercontent.com/zephyrproject-rtos/mcuboot/master/scripts/requirements.txt && \
    pip3 install -r https://raw.githubusercontent.com/nrfconnect/sdk-nrf/master/scripts/requirements.txt && \
    pip3 install west && \
    pip3 install sh

# Set the locale
ENV PATH=/opt/SEGGER/JLink:/opt/tools/nrfjprog:/opt/tools/mergehex:${PATH}
ENV NCS_PATH=/proj/ncs
ENV ZEPHYR_TOOLCHAIN_VARIANT=${TOOLCHAIN_VARIANT}
ENV ZEPHYR_BASE=$NCS_PATH/zephyr
ENV GNUARMEMB_TOOLCHAIN_PATH=/opt/toolchains/${GCC_ARM_NAME}
# ENV ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}
# ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig
ENV DISPLAY=:0

RUN mkdir -p ${NCS_PATH}
ADD script script
RUN if [ ${NCS_IN_DOCKER} = true ]; then ./script/ncs-init.sh ${NCS_PATH}; fi
RUN set +o noclobber
# ADD ./entrypoint.sh /home/user/entrypoint.sh
# RUN dos2unix /home/user/entrypoint.sh

EXPOSE 2331

# ENTRYPOINT ["/home/user/entrypoint.sh"]
# USER user

WORKDIR /proj
VOLUME ["/proj/ncs"];
VOLUME ["/proj"]
CMD ["/bin/bash"]

# ARG VNCPASSWD=zephyr
# RUN mkdir ~/.vnc && x11vnc -storepasswd ${VNCPASSWD} ~/.vnc/passwd