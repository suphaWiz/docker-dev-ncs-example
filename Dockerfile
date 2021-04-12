FROM mcr.microsoft.com/vscode/devcontainers/cpp:ubuntu-20.04

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


RUN apt -y update && \
	apt -y upgrade && \
	apt install --no-install-recommends -y \
	apt-transport-https \
	wget

# Tool versions to use
ENV ZSDK_VERSION=0.12.3
ENV GCC_ARM_NAME=gcc-arm-none-eabi-10-2020-q4-major
ENV CMAKE_VERSION=3.18.3
ENV RENODE_VERSION=1.11.0
ENV NRF_TOOLS_VERSION=10121
# ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig

# Download and extract archives to temp "dl" directory
WORKDIR /dl

# Download dependencies using wget
RUN wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://www.nordicsemi.com/-/media/Software-and-other-downloads/Desktop-software/nRF-command-line-tools/sw/Versions-10-x-x/10-12-1/nRFCommandLineTools10121Linuxamd64.tar.gz \
	&& wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/${GCC_ARM_NAME}-x86_64-linux.tar.bz2 \
	&& wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
	&& wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate --post-data 'accept_license_agreement=accepted&non_emb_ctr=confirmed&submit=Download+software' https://www.segger.com/downloads/jlink/JLink_Linux_x86_64.tgz \
	&& wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/zephyr-sdk-${ZSDK_VERSION}-x86_64-linux-setup.run \
	&& wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://github.com/renode/renode/releases/download/v${RENODE_VERSION}/renode_${RENODE_VERSION}_amd64.deb

# Extract archives
RUN chmod +x cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
	./cmake-${CMAKE_VERSION}-Linux-x86_64.sh --skip-license --prefix=/usr/local

RUN mkdir temp && mkdir -p /opt/tools
RUN tar -xf nRFCommandLineTools10121Linuxamd64.tar.gz -C temp && \
	tar -xf temp/nRF-Command-Line-Tools_10_12_1.tar -C /opt/tools/

RUN mkdir -p /opt/SEGGER/JLink
RUN tar -xf JLink_Linux_x86_64.tgz --strip-components=1 -C /opt/SEGGER/JLink/

RUN mkdir -p /opt/toolchains
RUN tar -xf ${GCC_ARM_NAME}-x86_64-linux.tar.bz2 -C /opt/toolchains/

RUN sh "zephyr-sdk-${ZSDK_VERSION}-x86_64-linux-setup.run" --quiet -- -d /opt/toolchains/zephyr-sdk-${ZSDK_VERSION} && \
	rm "zephyr-sdk-${ZSDK_VERSION}-x86_64-linux-setup.run"


# Download dependencies using apt
RUN apt install --no-install-recommends -y \
	gnupg \
	ca-certificates && \
	apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
	echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
	apt -y update && \
	apt install --no-install-recommends -y \
	autoconf \
	automake \
	build-essential \
	ccache \
	device-tree-compiler \
	dfu-util \
	file \
	g++ \
	g++-multilib \
	gcc \
	gcc-multilib \
	gcovr \
	git \
	git-core \
	gperf \
	gtk-sharp2 \
	iproute2 \
	iputils-ping \
	lcov \
	libglib2.0-dev \
	libgtk2.0-0 \
	libpcap-dev \
	libsdl2-dev \
	libncurses5 \
	libtool \
	locales \
	make \
	net-tools \
	ninja-build \
	openbox \
	pkg-config \
	python3-pip \
	qemu \
	socat \
	sudo \
	screen \
	texinfo \
	x11vnc \
	xvfb \
	xz-utils \
	dos2unix

RUN apt install --no-install-recommends -y \
	mono-complete \
	./renode_${RENODE_VERSION}_amd64.deb && \
	rm -rf /var/lib/apt/lists/*


# Download dependencies using pip
RUN pip3 install wheel west
RUN pip3 install -r https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements.txt 
RUN pip3 install -r https://raw.githubusercontent.com/zephyrproject-rtos/mcuboot/master/scripts/requirements.txt 
# RUN pip3 install -r https://raw.githubusercontent.com/nrfconnect/sdk-nrf/master/scripts/requirements.txt

# Remove dowloads
WORKDIR /
RUN rm -rf dl

# Build parameters and paths
ARG PROJ_PATH

ENV PROJ_PATH=${PROJ_PATH}
ENV PATH=/opt/SEGGER/JLink:/opt/tools/nrfjprog:/opt/tools/mergehex:${PATH}
ENV NCS_PATH=${PROJ_PATH}/ncs
ENV ZEPHYR_BASE=$NCS_PATH/zephyr
ENV GNUARMEMB_TOOLCHAIN_PATH=/opt/toolchains/${GCC_ARM_NAME}
ENV ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}

# Setup user
ENV USER_NAME=builder
ARG UID
ARG GID

# Rename user "vscode" from base image to USER_NAME
RUN groupmod -g ${GID} -n ${USER_NAME} vscode \
	&& usermod -u ${UID} -g ${GID} -G plugdev -md /home/${USER_NAME} -l ${USER_NAME} vscode \
	&& echo "$USER_NAME" 'ALL = (root) NOPASSWD: ALL' > /etc/sudoers.d/${USER_NAME} \
	&& chmod 0440 /etc/sudoers.d/${USER_NAME} \
	&& chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME} \
	&& passwd --delete ${USER_NAME}

# Add pre-start script in user dir
ADD script/pre-start.sh /home
RUN chmod +x /home/pre-start.sh && dos2unix /home/pre-start.sh

# Set user owneship of user dir and sub dirs
RUN mkdir -p ${PROJ_PATH} \
	&& mkdir ${NCS_PATH} \
	&& chown -R ${USER_NAME}:${USER_NAME} /home/${USER_NAME}

ENTRYPOINT ["/home/pre-start.sh"]
CMD ["/bin/bash"]

# Change to user
USER ${USER_NAME}
WORKDIR ${PROJ_PATH}
VOLUME ["${PROJ_PATH}"]
VOLUME ["${NCS_PATH}"];

EXPOSE 5900

ENV DEBIAN_FRONTEND noninteractive
ENV DISPLAY=:0
ARG VNCPASSWD=zephyr
RUN mkdir ~/.vnc && x11vnc -storepasswd ${VNCPASSWD} ~/.vnc/passwd