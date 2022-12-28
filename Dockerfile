# build with docker:
# sudo docker build \
# --build-arg VIVADO_TAR_HOST=0.0.0.0:8000 \
# --build-arg VIVADO_TAR_FILE=Xilinx_Unified_2021.2_1021_0703 \
# --build-arg VIVADO_VERSION=2021.2 . \
# -t vivado:2021.2


# Step 0 Install dependences
# Step 1 Xilinx
# Step 2 Questa Sim

FROM ubuntu:22.04

LABEL Alexey Kosinov <a.kosinov@1440.space>


# Install dependences (Xilinx & Mentor Graphics)
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
# RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN chmod 777 /home/docker
# USER docker

ARG HOST_ID="cat /sys/class/net/eth0/address | tr -d ':'"

# RUN echo "export PATH=$PATH:/opt/questasim/linux_x86_64" >> ~/.bashrc
# RUN echo "export PATH=$PATH:/opt/questasim/RUVM_2021.2" >> ~/.bashrc
# RUN echo "export LM_LICENSE_FILE=$LM_LICENSE_FILE:/opt/questasim/license.dat" >> ~/.bashrc

ENV PATH="${PATH}:/opt/questasim/linux_x86_64"
ENV PATH="${PATH}:/opt/questasim/RUVM_2021.2"
ENV LM_LICENSE_FILE="${LM_LICENSE_FILE}:/opt/questasim/license.dat"

# Copy config dir
COPY install_config /opt
COPY silent_install.sh /opt
COPY questa_install.sh /opt

ARG VIVADO_TAR_HOST

ARG VIVADO_TAR_FILE

ARG VIVADO_VERSION
ARG VITIS_VERSION

# Download and run the installation
# RUN wget -q -P /opt $VIVADO_TAR_HOST/$VIVADO_TAR_FILE.tar.gz \
# && cd /opt \
# && pv -f ${VIVADO_TAR_FILE}.tar.gz | tar -xzf - --directory . \
# && rm -rf ${VIVADO_TAR_FILE}.tar.gz \
# && chmod +x silent_install.sh \
# && chmod +x ${VIVADO_TAR_FILE}/xsetup.sh \
# && ./silent_install.sh -d /opt/${VIVADO_TAR_FILE} -c 1 \
# && ./silent_install.sh -d /opt/${VIVADO_TAR_FILE} -c 2

# Download and run the installation
RUN wget -q -P /opt $VIVADO_TAR_HOST/QuestaSim_2021.2.1_lin64.tar.gz \
&& cd /opt \
&& pv -f QuestaSim_2021.2.1_lin64.tar.gz | tar -xzf - --directory . \
&& rm -rf QuestaSim_2021.2.1_lin64.tar.gz \
&& cd QuestaSim_2021.2.1_lin64 \
&& python2 mgclicgen.py $(eval ${HOST_ID}) \
&& ls -l \
&& cd .. \
&& chmod +x questa_install.sh \
&& ./questa_install.sh \
&& ls -l \
&& cp QuestaSim_2021.2.1_lin64/license.dat /opt/questasim \
&& cp QuestaSim_2021.2.1_lin64/pubkey_verify /opt/questasim \
&& cd /opt/questasim \
&& ls -l \
&& ls -l bin\
&& chmod +x pubkey_verify \
&& ./pubkey_verify -y \
&& vsim -h \
&& ip addr


# Post installation procedures

# Add vivado tools to path (root)
# RUN echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /root/.profile
# RUN echo "source /opt/Xilinx/Vitis/${VITIS_VERSION}/settings64.sh" >> /root/.profile

# Copy license file (root)
# RUN mkdir -p /root/.Xilinx
# COPY license/*.lic /root/.Xilinx/

##########################################################################################################
# User profile
##########################################################################################################

# Add vivado tools to path
RUN echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /home/docker/.profile
RUN echo "source /opt/Xilinx/Vitis/${VITIS_VERSION}/settings64.sh" >> /home/docker/.profile

# Copy license file
RUN mkdir /home/docker/.Xilinx
COPY license/*.lic /home/docker/.Xilinx/

