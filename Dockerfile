# build docker:
# sudo docker build \
# --build-arg VIVADO_TAR_HOST=0.0.0.0:8000 \
# --build-arg VIVADO_TAR_FILE=Xilinx_Unified_2021.2_1021_0703 \
# --build-arg VIVADO_TAR_UPDATE=Xilinx_Vivado_Vitis_Update_2021.2.1_1219_1431 \
# --build-arg VIVADO_VERSION=2021.2 . \
# --build-arg QUESTA_TAR_FILE=QuestaSim_2021.2.1_lin64 \
# -t vivado:2021.2

# run docker:
# sudo docker run \
# --env="DISPLAY" 
# --volume="$HOME/.Xauthority:/root/.Xauthority:ro" 
# --rm 
# -it vivado:2021.2


FROM ubuntu:20.04

LABEL Alexey Kosinov <a.kosinov@1440.space>

# Install dependences
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y \
  apt-utils \
  coreutils \
  default-jre \
  # xorg \
  wget \
  pv \
  python2 \
  # vim \
  sudo \
  locales \
  build-essential \
  libglib2.0-0 \
  libsm6 \
  libxi6 \
  libxrender1 \
  libxrandr2 \
  libfreetype6 \
  libfontconfig \
  libxft2 \
  lib32ncurses6 \
  libxext6 \
  # git \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Make a Vivado user
RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo
RUN chmod 777 /home/docker

# Get MAC Address (used for the license)
ARG HOST_ID="cat /sys/class/net/eth0/address | tr -d ':'"

# Questa Sim env
ENV PATH="${PATH}:/opt/questasim/linux_x86_64"
ENV PATH="${PATH}:/opt/questasim/RUVM_2021.2"
ENV LM_LICENSE_FILE="${LM_LICENSE_FILE}:/opt/questasim/license.dat"

# Vivado env
ENV PATH="${PATH}:/opt/Xilinx/Vivado/2021.2/bin/unwrapped/lnx64.o"
ENV PATH="${PATH}:/opt/Xilinx/Vitis/2021.2/bin/unwrapped/lnx64.o"
ENV XILINX="${XILINX}:/opt/Xilinx"
ENV LIBRARY_PATH="${LIBRARY_PATH}:/usr/lib/x86_64-linux-gnu"
RUN echo 'alias vivado="vivado -log /tmp/vivado.log -journal /tmp/vivado.jou"' >> ~/.bashrc


# GPG import xilinx key to verify downloaded packages
# COPY xilinx-master-signing-key.asc /opt
# COPY Xilinx_Unified_2021.2_1021_0703.tar.gz.sig /opt
# COPY Xilinx_Vivado_Vitis_Update_2021.2.1_1219_1431.tar.gz.sig /opt
# ARG GPG_XIL_KEY="gpg --list-packets /opt/xilinx-master-signing-key.asc | awk '$1=="keyid:"{print$2}'"
# RUN gpg --list-packets /opt/xilinx-master-signing-key.asc | awk '$1=="keyid:"{print$2}'
# RUN echo  GPG_XIL_KEY is $(eval ${HOST_ID})
# RUN expect -c 'spawn gpg --edit-key ${GPG_XIL_KEY} trust quit; send "5\ry\r"; expect eof'
# RUN gpg --list-keys

# Xilinx License dir
ADD install_config /opt
ADD license /opt

# Questa Sim install script
COPY questa_install.sh /opt

ARG VIVADO_TAR_HOST
ARG VIVADO_TAR_FILE
ARG VIVADO_TAR_UPDATE
ARG QUESTA_TAR_FILE
ARG VIVADO_VERSION
ARG VITIS_VERSION

# Vivado, Vitis & Update Download and run the installation
RUN wget --no-verbose --show-progress --progress=bar:force:noscroll -P /opt $VIVADO_TAR_HOST/${VIVADO_TAR_FILE}.tar.gz \
&& cd /opt \
&& pv -f ${VIVADO_TAR_FILE}.tar.gz | tar -xzf - --directory . \
&& rm -rf ${VIVADO_TAR_FILE}.tar.gz \
&& chmod +x $VIVADO_TAR_FILE/xsetup \
&& $VIVADO_TAR_FILE/xsetup -a XilinxEULA,3rdPartyEULA -b Install -c vivado.txt \
&& $VIVADO_TAR_FILE/xsetup -a XilinxEULA,3rdPartyEULA -b Add -c vitis.txt \
&& rm -rf $VIVADO_TAR_FILE \
&& wget --no-verbose --show-progress --progress=bar:force:noscroll -P /opt $VIVADO_TAR_HOST/${VIVADO_TAR_UPDATE}.tar.gz \
&& pv -f ${VIVADO_TAR_UPDATE}.tar.gz | tar -xzf - --directory . \
&& rm -rf ${VIVADO_TAR_UPDATE}.tar.gz \
&& chmod +x $VIVADO_TAR_UPDATE/xsetup \
&& $VIVADO_TAR_UPDATE/xsetup -a XilinxEULA,3rdPartyEULA -b Update -c vivado.txt \
&& $VIVADO_TAR_UPDATE/xsetup -a XilinxEULA,3rdPartyEULA -b Update -c vitis.txt \
&& rm -rf $VIVADO_TAR_UPDATE \
&& rm -rf *.txt

# Download and run the installation Questa Sim
# RUN wget --no-verbose --show-progress --progress=bar:force:noscroll -P /opt $VIVADO_TAR_HOST/${QUESTA_TAR_FILE}.tar.gz \
# && cd /opt \
# && pv -f ${QUESTA_TAR_FILE}.tar.gz | tar -xzf - --directory . \
# && rm -rf ${QUESTA_TAR_FILE}.tar.gz \
# && cd ${QUESTA_TAR_FILE} \
# && python2 mgclicgen.py $(eval ${HOST_ID}) \
# && cd .. \
# && chmod +x questa_install.sh \
# && ./questa_install.sh \
# && cp ${QUESTA_TAR_FILE}/license.dat /opt/questasim \
# && cp ${QUESTA_TAR_FILE}/pubkey_verify /opt/questasim \
# && cd /opt/questasim \
# && chmod +x pubkey_verify \
# && ./pubkey_verify -y \
# && vsim -h \
# && rm -rf /opt/${QUESTA_TAR_FILE}




# Add vivado tools to path
RUN echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /root/.profile
RUN echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /home/docker/.profile

RUN echo "source /opt/Xilinx/Vitis/${VITIS_VERSION}/settings64.sh" >> /root/.profile
RUN echo "source /opt/Xilinx/Vitis/${VITIS_VERSION}/settings64.sh" >> /home/docker/.profile

# Copy license file
RUN mkdir /root/.Xilinx
RUN mkdir /home/docker/.Xilinx

COPY license/*.lic /root/.Xilinx/
COPY license/*.lic /home/docker/.Xilinx/

RUN rm -rf /opt/*.lic

RUN echo "Docker image build succesfully"
