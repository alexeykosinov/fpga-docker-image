# build with docker build --build-arg VIVADO_TAR_HOST=host:port --build-arg VIVADO_TAR_FILE=Xilinx_Vivado_SDK_2016.3_1011_1 -t vivado .

# Step 0 Install dependences
# Step 1 Xilinx
# Step 2 Questa Sim

FROM ubuntu:22.04

MAINTAINER Alexey Kosinov <a.kosinov@1440.space>

# Install dependences
RUN apt-get update && apt-get install -y \
  wget \
  build-essential \
  libglib2.0-0 \
  libsm6 \
  libxi6 \
  libxrender1 \
  libxrandr2 \
  libfreetype6 \
  libfontconfig \
  git

# Copy config dir
COPY install_config /opt

ARG VIVADO_TAR_HOST

ARG VIVADO_TAR_FILE
ARG VITIS_TAR_FILE

ARG VIVADO_VERSION
ARG VITIS_VERSION

# Download and run the installation
RUN echo "PART 1 ### XILINX VIVDO INSTALLATION ###"
RUN echo "Downloading ${VIVADO_TAR_FILE} from ${VIVADO_TAR_HOST}"
RUN wget ${VIVADO_TAR_HOST}/${VIVADO_TAR_FILE}.tar.gz -q
RUN echo "Extracting Vivado tar file"
RUN tar xzf ${VIVADO_TAR_FILE}.tar.gz
RUN ./silent_install.sh -d ${VIVADO_TAR_FILE} -c 1
RUN rm -rf ${VIVADO_TAR_FILE}*

RUN echo "PART 1 ### XILINX VITIS INSTALLATION ###"
RUN echo "Downloading ${VIVADO_TAR_FILE} from ${VIVADO_TAR_HOST}"
RUN wget ${VIVADO_TAR_HOST}/${VITIS_TAR_FILE}.tar.gz -q
RUN echo "Extracting Vivado tar file"
RUN tar xzf ${VITIS_TAR_FILE}.tar.gz
RUN ./silent_install.sh -d ${VITIS_TAR_FILE} -c 2
RUN rm -rf ${VITIS_TAR_FILE}*




# Post installation procedures

# Add vivado tools to path (root)
RUN echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /root/.profile
RUN echo "source /opt/Xilinx/Vivado/${VITIS_VERSION}/settings64.sh" >> /root/.profile

# Copy license file (root)
RUN mkdir -p /root/.Xilinx
COPY *.lic /root/.Xilinx/

##########################################################################################################
# User profile
##########################################################################################################

# Make a Vivado user
RUN adduser --disabled-password --gecos '' user
USER user
WORKDIR /home/user

# Add vivado tools to path
RUN echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh" >> /home/user/.profile
RUN echo "source /opt/Xilinx/Vivado/${VITIS_VERSION}/settings64.sh" >> /home/user/.profile

# Copy license file
RUN mkdir /home/user/.Xilinx
COPY *.lic /home/user/.Xilinx/

