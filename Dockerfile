FROM mcr.microsoft.com/vscode/devcontainers/cpp:ubuntu-20.04

ARG TOOLCHAIN_VARIANT=gnuarmemb
ARG UID=1001
ARG GID=1001
ARG PROJ_PATH=/work/proj

ENV ZSDK_VERSION=0.11.4
ENV GCC_ARM_NAME=gcc-arm-none-eabi-10-2020-q4-major
ENV CMAKE_VERSION=3.18.3
ENV RENODE_VERSION=1.11.0
ENV NRF_TOOLS_VERSION=10121
ENV TZ=Europe/Berlin

# Set the locale
ENV PATH=/opt/SEGGER/JLink:/opt/tools/nrfjprog:/opt/tools/mergehex:${PATH}
ENV NCS_PATH=${PROJ_PATH}/ncs
ENV ZEPHYR_TOOLCHAIN_VARIANT=${TOOLCHAIN_VARIANT}
ENV ZEPHYR_BASE=$NCS_PATH/zephyr
ENV GNUARMEMB_TOOLCHAIN_PATH=/opt/toolchains/${GCC_ARM_NAME}
ENV ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}
# ENV PKG_CONFIG_PATH=/usr/lib/i386-linux-gnu/pkgconfig
ENV DEBIAN_FRONTEND noninteractive
ENV DISPLAY=:0


RUN groupadd -g $GID -o user
RUN useradd -u $UID -m -g user -G plugdev user \
	&& echo 'user ALL = NOPASSWD: ALL' > /etc/sudoers.d/user \
	&& chmod 0440 /etc/sudoers.d/user
RUN chown -R user:user /home/user

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt -y update && \
	apt -y upgrade && \
	apt install --no-install-recommends -y \
	dos2unix \
	wget \
	python3-pip

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Download and extract archives to temp "dl" directory
WORKDIR /dl

# Download dependencies using wget
RUN wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://www.nordicsemi.com/-/media/Software-and-other-downloads/Desktop-software/nRF-command-line-tools/sw/Versions-10-x-x/10-12-1/nRFCommandLineTools10121Linuxamd64tar.gz
RUN	wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/${GCC_ARM_NAME}-x86_64-linux.tar.bz2
RUN	wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh
RUN	wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate --post-data 'accept_license_agreement=accepted&non_emb_ctr=confirmed&submit=Download+software' https://www.segger.com/downloads/jlink/JLink_Linux_x86_64.tgz
RUN	wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/zephyr-sdk-${ZSDK_VERSION}-setup.run
RUN	wget -q --show-progress --progress=bar:force:noscroll --no-check-certificate https://github.com/renode/renode/releases/download/v${RENODE_VERSION}/renode_${RENODE_VERSION}_amd64.deb

# Extract archives
RUN chmod +x cmake-${CMAKE_VERSION}-Linux-x86_64.sh && \
	./cmake-${CMAKE_VERSION}-Linux-x86_64.sh --skip-license --prefix=/usr/local

RUN mkdir temp && mkdir -p /opt/tools
RUN tar -xf nRFCommandLineTools10121Linuxamd64tar.gz -C temp && \
	tar -xf temp/nRF-Command-Line-Tools_10_12_1.tar -C /opt/tools/

RUN mkdir -p /opt/SEGGER/JLink
RUN tar -xf JLink_Linux_x86_64.tgz --strip-components=1 -C /opt/SEGGER/JLink/

RUN mkdir -p /opt/toolchains
RUN tar -xf ${GCC_ARM_NAME}-x86_64-linux.tar.bz2 -C /opt/toolchains/

RUN sh "zephyr-sdk-${ZSDK_VERSION}-setup.run" --quiet -- -d /opt/toolchains/zephyr-sdk-${ZSDK_VERSION} && \
	rm "zephyr-sdk-${ZSDK_VERSION}-setup.run"


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
	# doxygen \
	file \
	g++ \
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
	mono-complete \
	net-tools \
	ninja-build \
	openbox \
	pkg-config \
	# python3-dev \
	# python3-ply \
	# python3-setuptools \
	# python-xdg \
	qemu \
	socat \
	sudo \
	screen \
	texinfo \
	# valgrind \
	x11vnc \
	xvfb \
	xz-utils && \
	apt install -y ./renode_${RENODE_VERSION}_amd64.deb && \
	rm -rf /var/lib/apt/lists/*


# Download dependencies using pip
RUN pip3 install wheel &&\
	pip3 install -r https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/master/scripts/requirements.txt && \
	pip3 install -r https://raw.githubusercontent.com/zephyrproject-rtos/mcuboot/master/scripts/requirements.txt && \
	pip3 install -r https://raw.githubusercontent.com/nrfconnect/sdk-nrf/master/scripts/requirements.txt && \
	pip3 install sh \
	west

# Remove dowloads
WORKDIR /
RUN rm -rf dl

# Add scripts
ADD script/pre-start.sh /home/user/
WORKDIR /home/user
RUN chmod +x pre-start.sh && dos2unix pre-start.sh

EXPOSE 5900
ENTRYPOINT ["/home/user/pre-start.sh"]
CMD ["/bin/bash"]
# USER user

WORKDIR ${PROJ_PATH}
VOLUME ["${PROJ_PATH}"]
VOLUME ["${NCS_PATH}"];

ARG VNCPASSWD=zephyr
RUN mkdir ~/.vnc && x11vnc -storepasswd ${VNCPASSWD} ~/.vnc/passwd