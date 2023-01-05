FROM ubuntu:20.04

LABEL Alexey Kosinov <a.kosinov@1440.space>

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
    --no-install-recommends \
    apt-utils \
    coreutils \
    default-jre \
    gcc \
    xorg \
    wget \
    pv \
    python2 \
    vim \
    sudo \
    locales \
    build-essential \
    libtcmalloc-minimal4 \
    libglib2.0-0 \
    libsm6 \
    libxi6 \
    libtinfo5 \
    libxrender1 \
    libxrandr2 \
    libfreetype6 \
    libfontconfig \
    libxft2 \
    lib32ncurses6 \
    libxext6 \
    git \
&&  apt-get clean \
&&  rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ARG USER=docker
ARG PASS="docker"
RUN useradd -m -s /bin/bash $USER && echo "$USER:$PASS" | chpasswd

# Get MAC Address (used for the license)
ARG HOST_ID="cat /sys/class/net/eth0/address | tr -d ':'"

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
ADD questa_install.sh /opt

ARG VIVADO_TAR_HOST
ARG VIVADO_TAR_FILE
ARG VIVADO_TAR_UPDATE
ARG QUESTA_TAR_FILE
ARG VIVADO_VERSION
ARG VITIS_VERSION

# Download and run the installation Questa Sim
RUN wget --no-verbose --show-progress --progress=bar:force:noscroll -P /opt $VIVADO_TAR_HOST/${QUESTA_TAR_FILE}.tar.gz \
&&  cd /opt \
&&  pv -f ${QUESTA_TAR_FILE}.tar.gz | tar -xzf - --directory . \
&&  rm -rf ${QUESTA_TAR_FILE}.tar.gz \
&&  cd ${QUESTA_TAR_FILE} \
&&  python2 mgclicgen.py $(eval ${HOST_ID}) \
&&  cd .. \
&&  chmod +x questa_install.sh \
&&  ./questa_install.sh -tgt /opt -msiloc /home/docker \
&&  cp ${QUESTA_TAR_FILE}/license.dat /opt/questasim \
&&  cp ${QUESTA_TAR_FILE}/pubkey_verify /opt/questasim \
&&  cd /opt/questasim \
&&  chmod +x pubkey_verify \
&&  ./pubkey_verify -y \
&&  rm -rf /opt/${QUESTA_TAR_FILE} \
&&  rm -rf /opt/questasim/pubkey_verify \
&&  rm -rf /opt/questa_install.sh

# Vivado, Vitis & Update Download and run the installation
RUN wget --no-verbose --show-progress --progress=bar:force:noscroll -P /opt $VIVADO_TAR_HOST/${VIVADO_TAR_FILE}.tar.gz \
&&  cd /opt \
&&  pv -f ${VIVADO_TAR_FILE}.tar.gz | tar -xzf - --directory . \
&&  rm -rf ${VIVADO_TAR_FILE}.tar.gz \
&&  chmod +x $VIVADO_TAR_FILE/xsetup \
# &&  $VIVADO_TAR_FILE/xsetup -a XilinxEULA,3rdPartyEULA -b Install -c vivado.txt \
&&  $VIVADO_TAR_FILE/xsetup -a XilinxEULA,3rdPartyEULA -b Install -c vitis.txt \
&&  rm -rf $VIVADO_TAR_FILE \
&&  wget --no-verbose --show-progress --progress=bar:force:noscroll -P /opt $VIVADO_TAR_HOST/${VIVADO_TAR_UPDATE}.tar.gz \
&&  pv -f ${VIVADO_TAR_UPDATE}.tar.gz | tar -xzf - --directory . \
&&  rm -rf ${VIVADO_TAR_UPDATE}.tar.gz \
&&  chmod +x $VIVADO_TAR_UPDATE/xsetup \
# &&  $VIVADO_TAR_UPDATE/xsetup -a XilinxEULA,3rdPartyEULA -b Update -c vivado.txt \
&&  $VIVADO_TAR_UPDATE/xsetup -a XilinxEULA,3rdPartyEULA -b Update -c vitis.txt \
&&  rm -rf $VIVADO_TAR_UPDATE \
&&  rm -rf *.txt


# Add tools path, env & etc.
RUN echo 'PATH="${PATH}:/opt/questasim/linux_x86_64"'                           >> /home/docker/.bashrc \
&&  echo 'PATH="${PATH}:/opt/questasim/RUVM_2021.2"'                            >> /home/docker/.bashrc \
&&  echo 'LM_LICENSE_FILE="${LM_LICENSE_FILE}:/opt/questasim/license.dat"'      >> /home/docker/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Xilinx/Vivado/2021.2/bin/unwrapped/lnx64.o"'       >> /home/docker/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Xilinx/Vitis/2021.2/bin/unwrapped/lnx64.o"'        >> /home/docker/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Xilinx/Vitis_HLS/2021.2/bin/unwrapped/lnx64.o"'    >> /home/docker/.bashrc \
&&  echo 'XILINX="${XILINX}:/opt/Xilinx"'                                       >> /home/docker/.bashrc \
&&  echo 'alias vivado="vivado -log /tmp/vivado.log -journal /tmp/vivado.jou"'  >> /home/docker/.bashrc \
&&  echo "source /opt/Xilinx/Vitis_HLS/${VIVADO_VERSION}/settings64.sh"         >> /home/docker/.bashrc \
&&  echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh"            >> /home/docker/.bashrc \
&&  echo "source /opt/Xilinx/Vitis/${VIVADO_VERSION}/settings64.sh"             >> /home/docker/.bashrc

# Copy license file
USER docker
RUN mkdir ~/.Xilinx
COPY license/*.lic ~/.Xilinx/


USER root

RUN rm -rf /opt/*.lic

USER docker
