FROM ubuntu:20.04

LABEL Alexey Kosinov <a.kosinov@1440.space>
LABEL Vivado 2021.2.1 & Questa SIM-64 Docker Image

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
    --no-install-recommends \
    apt-utils \
    coreutils \
    default-jre \
    gcc \
    wget \
    pv \
    python2 \
    vim \
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
    libxmu6 \
    libxext-dev \
    libxt6 \
    git \
&&  apt-get clean \
&&  rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN adduser --disabled-password --shell /bin/bash --gecos '' jenkins

# Get MAC Address (used for the license)
ARG HOST_ID="cat /sys/class/net/eth0/address | tr -d ':'"

# Xilinx License dir
ADD license /opt
ADD vitis_install.txt /opt
ADD questa_install.sh /opt
ADD compile_sim.tcl /opt
ADD matlab_install.txt /opt

ARG VIVADO_TAR_HOST
ARG VIVADO_TAR_FILE
ARG VIVADO_TAR_UPDATE
ARG QUESTA_TAR_FILE
ARG VIVADO_VERSION
ARG VITIS_VERSION
ARG MATLAB_TAR_FILE
ARG MATLAB_VER


# Download and run the installation of MATLAB
RUN wget --no-verbose --show-progress --progress=bar:force:noscroll -P /opt $VIVADO_TAR_HOST/${MATLAB_TAR_FILE}.tar.gz \
&&  cd /opt \
&&  pv -f ${MATLAB_TAR_FILE}.tar.gz | tar -xzf - --directory . \
&&  rm -rf ${MATLAB_TAR_FILE}.tar.gz \
&&  chmod -R 777 ${MATLAB_TAR_FILE} \
&&  cd ${MATLAB_TAR_FILE} \
&&  chmod +x install \
&&  ./install -inputFile /opt/matlab_install.txt \
&& cat /tmp/matlab.log \
&& cp libmwlmgrimpl.so /opt/Matlab/R2022b/bin/glnxa64/matlab_startup_plugins/lmgrimpl \
&& rm -rf ${MATLAB_TAR_FILE}

# Download and run the installation Questa Sim
RUN wget --no-verbose --show-progress --progress=bar:force:noscroll -P /opt $VIVADO_TAR_HOST/${QUESTA_TAR_FILE}.tar.gz \
&&  cd /opt \
&&  pv -f ${QUESTA_TAR_FILE}.tar.gz | tar -xzf - --directory . \
&&  rm -rf ${QUESTA_TAR_FILE}.tar.gz \
&&  cd ${QUESTA_TAR_FILE} \
&&  python2 mgclicgen.py $(eval ${HOST_ID}) \
&&  cd .. \
&&  chmod +x questa_install.sh \
&&  ./questa_install.sh -tgt /opt -msiloc /home/jenkins \
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
&&  $VIVADO_TAR_FILE/xsetup -a XilinxEULA,3rdPartyEULA -b Install -c vitis_install.txt \
&&  rm -rf $VIVADO_TAR_FILE \
&&  wget --no-verbose --show-progress --progress=bar:force:noscroll -P /opt $VIVADO_TAR_HOST/${VIVADO_TAR_UPDATE}.tar.gz \
&&  pv -f ${VIVADO_TAR_UPDATE}.tar.gz | tar -xzf - --directory . \
&&  rm -rf ${VIVADO_TAR_UPDATE}.tar.gz \
&&  chmod +x $VIVADO_TAR_UPDATE/xsetup \
&&  $VIVADO_TAR_UPDATE/xsetup -a XilinxEULA,3rdPartyEULA -b Update -c vitis_install.txt \
&&  rm -rf $VIVADO_TAR_UPDATE \
&&  rm -rf *.txt


# Add tools path, env & etc.
RUN echo 'PATH="${PATH}:/opt/questasim/linux_x86_64"'                           >> /home/jenkins/.bashrc \
&&  echo 'PATH="${PATH}:/opt/questasim/RUVM_2021.2"'                            >> /home/jenkins/.bashrc \
&&  echo 'export LM_LICENSE_FILE="/opt/questasim/license.dat"'                  >> /home/jenkins/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Xilinx/Vivado/2021.2/bin/unwrapped/lnx64.o"'       >> /home/jenkins/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Xilinx/Vitis/2021.2/bin/unwrapped/lnx64.o"'        >> /home/jenkins/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Xilinx/Vitis_HLS/2021.2/bin/unwrapped/lnx64.o"'    >> /home/jenkins/.bashrc \
&&  echo 'XILINX="${XILINX}:/opt/Xilinx"'                                       >> /home/jenkins/.bashrc \
&&  echo 'alias vivado="vivado -log /tmp/vivado.log -journal /tmp/vivado.jou"'  >> /home/jenkins/.bashrc \
&&  echo "source /opt/Xilinx/Vitis_HLS/${VIVADO_VERSION}/settings64.sh"         >> /home/jenkins/.bashrc \
&&  echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh"            >> /home/jenkins/.bashrc \
&&  echo "source /opt/Xilinx/Vitis/${VIVADO_VERSION}/settings64.sh"             >> /home/jenkins/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Matlab/R2022b/bin"'                                >> /home/jenkins/.bashrc

RUN echo 'PATH="${PATH}:/opt/questasim/linux_x86_64"'                           >> /root/.bashrc \
&&  echo 'PATH="${PATH}:/opt/questasim/RUVM_2021.2"'                            >> /root/.bashrc \
&&  echo 'export LM_LICENSE_FILE="/opt/questasim/license.dat"'                  >> /root/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Xilinx/Vivado/2021.2/bin/unwrapped/lnx64.o"'       >> /root/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Xilinx/Vitis/2021.2/bin/unwrapped/lnx64.o"'        >> /root/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Xilinx/Vitis_HLS/2021.2/bin/unwrapped/lnx64.o"'    >> /root/.bashrc \
&&  echo 'XILINX="${XILINX}:/opt/Xilinx"'                                       >> /root/.bashrc \
&&  echo 'alias vivado="vivado -log /tmp/vivado.log -journal /tmp/vivado.jou"'  >> /root/.bashrc \
&&  echo "source /opt/Xilinx/Vitis_HLS/${VIVADO_VERSION}/settings64.sh"         >> /root/.bashrc \
&&  echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh"            >> /root/.bashrc \
&&  echo "source /opt/Xilinx/Vitis/${VIVADO_VERSION}/settings64.sh"             >> /root/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Matlab/R2022b/bin"'                                >> /root/.bashrc




# Copy license file
USER jenkins
RUN mkdir ~/.Xilinx
COPY license/*.lic ~/.Xilinx/

USER root
COPY license/*.lic ~/.Xilinx/

RUN rm -rf /opt/*.lic

USER jenkins

# Next step is we could compile simulation libararies for Questa
# RUN vivado -nolog -nojournal -notrace -mode tcl -source compile_sim.tcl









