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

MAINTAINER Alexey Kosinov <a.kosinov@1440.space>


# Install dependences (Xilinx & Mentor Graphics)
RUN apt-get update && apt-get -y upgrade && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y \
  apt-utils \
  default-jre \
  xorg \
  wget \
  pv \
  vim \
  sudo \
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
  git \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Copy config dir
COPY install_config /opt
COPY silent_install.sh /opt

ARG VIVADO_TAR_HOST

ARG VIVADO_TAR_FILE

ARG VIVADO_VERSION
ARG VITIS_VERSION

# Download and run the installation
RUN echo "Downloading ${VIVADO_TAR_FILE} from ${VIVADO_TAR_HOST}"
RUN wget -q -P /opt $VIVADO_TAR_HOST/$VIVADO_TAR_FILE.tar.gz
RUN ls -l
RUN echo "Extracting Vivado tar file"
RUN pv ${VIVADO_TAR_FILE}.tar.gz | tar -xzf - --directory /opt/
#RUN tar xzf ${VIVADO_TAR_FILE}.tar.gz –C /opt/
RUN ls -l
RUN cd /opt/
RUN ls -l
RUN chmod +x silent_install.sh
RUN ./silent_install.sh -d ${VIVADO_TAR_FILE} -c 1
RUN ./silent_install.sh -d ${VIVADO_TAR_FILE} -c 2
# RUN rm -rf $VIVADO_TAR_FILE*




# Post installation procedures

# Add vivado tools to path (root)
RUN echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /root/.profile
RUN echo "source /opt/Xilinx/Vitis/${VITIS_VERSION}/settings64.sh" >> /root/.profile

# Copy license file (root)
RUN mkdir -p /root/.Xilinx
COPY license/*.lic /root/.Xilinx/

##########################################################################################################
# User profile
##########################################################################################################

# Make a Vivado user
RUN adduser --disabled-password --gecos '' user
USER user
WORKDIR /home/user

# Add vivado tools to path
RUN echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /home/user/.profile
RUN echo "source /opt/Xilinx/Vitis/${VITIS_VERSION}/settings64.sh" >> /home/user/.profile

# Copy license file
RUN mkdir /home/user/.Xilinx
COPY license/*.lic /home/user/.Xilinx/

