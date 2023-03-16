FROM ubuntu:20.04

LABEL Alexey Kosinov <a.kosinov@1440.space>
LABEL Vladislav Borshch <v.borshch@1440.space>
LABEL Vivado 2021.2.1, Questa SIM-64 2021.2 & Matlab R2022b Docker Image

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
    --no-install-recommends \
    apt-utils \
    coreutils \
    default-jre \
    gcc \
    smbclient \
    pv \
    python2 \
    vim \
    locales \
    build-essential \
    libtcmalloc-minimal4 \
    dpkg-dev \
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
    libncurses5 \
    libxext6 \
    libxmu6 \
    libxext-dev \
    libstdc++6 \
    libxt6 \
    git \
    x11-utils \
    libgtk-3-dev \
    xvfb \
    curl \
    gosu \
    sudo \
    python3.9 \
    python3.9-distutils \
    python3.9-dev \
    python3-pip \
&&  apt-get clean \
&&  rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN adduser --disabled-password --shell /bin/bash --gecos '' docker
RUN echo docker:help | chpasswd

# Xilinx License dir
ADD vitis_install.txt /opt
ADD questa_install.sh /opt
ADD compile_sim.tcl /opt
ADD matlab_install.txt /opt

ARG SMB_HOST
ARG SMB_USER
ARG SMB_PWD
ARG VIVADO_TAR_FILE
ARG VIVADO_TAR_UPDATE
ARG QUESTA_TAR_FILE
ARG VIVADO_VERSION
ARG VITIS_VERSION
ARG MATLAB_TAR_FILE
ARG MATLAB_VER


# Download and run the installation of MATLAB
RUN cd /opt \
&& smbget smb://${SMB_HOST}/Distrib/Engineering/Matlab/MATLAB_R2022b_Linux/${MATLAB_TAR_FILE}.tar.gz -U "${SMB_USER}%${SMB_PWD}" -v \
&&  pv -f ${MATLAB_TAR_FILE}.tar.gz | tar -xzf - --directory . \
&&  rm -rf ${MATLAB_TAR_FILE}.tar.gz \
&&  chmod -R 777 ${MATLAB_TAR_FILE} \
&&  cd ${MATLAB_TAR_FILE} \
&&  chmod +x install \
&&  ./install -inputFile /opt/matlab_install.txt \
&&  cat /tmp/matlab.log \
&&  cp libmwlmgrimpl.so /opt/Matlab/R2022b/bin/glnxa64/matlab_startup_plugins/lmgrimpl \
&&  rm -rf ${MATLAB_TAR_FILE} \
&&  rm -rf /opt/${MATLAB_TAR_FILE}

# Download and run the installation of Questa Sim
RUN cd /opt \
&&  smbget smb://${SMB_HOST}/Distrib/Engineering/Siemens/${QUESTA_TAR_FILE}.tar.gz -U "${SMB_USER}%${SMB_PWD}" -v \
&&  pv -f ${QUESTA_TAR_FILE}.tar.gz | tar -xzf - --directory . \
&&  rm -rf ${QUESTA_TAR_FILE}.tar.gz \
&&  cd ${QUESTA_TAR_FILE} \
&&  cp mgclicgen.py /opt \
&&  cd .. \
&&  chmod +x questa_install.sh \
&&  ./questa_install.sh -tgt /opt -msiloc /home/docker \
&&  cp ${QUESTA_TAR_FILE}/pubkey_verify /opt/questasim \
&&  cd /opt/questasim \
&&  chmod +x pubkey_verify \
&&  ./pubkey_verify -y \
&&  rm -rf /opt/${QUESTA_TAR_FILE} \
&&  rm -rf /opt/questasim/pubkey_verify \
&&  rm -rf /opt/questa_install.sh \
&&  mv /opt/questasim/gcc-7.4.0-linux_x86_64/lib64/libstdc++.so.6 ./libstdc++.so.6.bak

# Vivado & Vitis download and run the installation
RUN cd /opt \
&&  smbget smb://${SMB_HOST}/Distrib/Engineering/Xilinx/${VIVADO_TAR_FILE}.tar.gz -U "${SMB_USER}%${SMB_PWD}" -v \
&&  pv -f ${VIVADO_TAR_FILE}.tar.gz | tar -xzf - --directory . \
&&  rm -rf ${VIVADO_TAR_FILE}.tar.gz \
&&  chmod +x $VIVADO_TAR_FILE/xsetup \
&&  $VIVADO_TAR_FILE/xsetup -a XilinxEULA,3rdPartyEULA -b Install -c vitis_install.txt \
&&  rm -rf $VIVADO_TAR_FILE

# Vivado & Vitis updates download and install
RUN cd /opt \
&&  smbget smb://${SMB_HOST}/Distrib/Engineering/Xilinx/${VIVADO_TAR_UPDATE}.tar.gz -U "${SMB_USER}%${SMB_PWD}" -v \
&&  pv -f ${VIVADO_TAR_UPDATE}.tar.gz | tar -xzf - --directory . \
&&  rm -rf ${VIVADO_TAR_UPDATE}.tar.gz \
&&  chmod +x $VIVADO_TAR_UPDATE/xsetup \
&&  $VIVADO_TAR_UPDATE/xsetup -a XilinxEULA,3rdPartyEULA -b Update -c vitis_install.txt \
&&  rm -rf $VIVADO_TAR_UPDATE \
&&  rm -rf *.txt

# Install python3.9 as default. Install pip3 and packages
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1 \
&&  update-alternatives --config python3 \
&&  umask 022 && pip install --upgrade pip setuptools wheel libpython \
&&  python3 -m pip install /opt/Matlab/R2022b/extern/engines/python

# Copy Xilinx licenses to Xilinx folder
COPY license /opt/Xilinx/

# Not really necessary, just to make it easier to install packages on the run...
RUN echo "root:docker" | chpasswd

SHELL ["/bin/bash", "-c"]

# Workaround for Questa's libs conflict
RUN cd /opt/questasim/gcc-5.3.0-linux_x86_64/libexec/gcc/x86_64-unknown-linux-gnu/5.3.0/ \
&&  rm ld && ln -s /usr/bin/ld ld

# Compile Xilinx's libs and attach compiled libs to QuestaSim modelsim.ini
RUN export CPATH=/usr/include/x86_64-linux-gnu \
&&  export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LIBRARY_PATH \
&&  export PATH=$PATH:/opt/questasim/linux_x86_64 \
&&  source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh \
&&  cd /opt/questasim/xilinx/ \
&&  vivado -nojournal -notrace -mode batch -source /opt/compile_sim.tcl \
&&  chmod 666 /opt/questasim/modelsim.ini \
&&  for folder in /opt/questasim/xilinx/*; do vmap -modelsimini /opt/questasim/modelsim.ini $(basename $folder) $folder; done \
&&  chmod 444 /opt/questasim/modelsim.ini

RUN echo 'PATH="${PATH}:/opt/questasim/linux_x86_64"'                                                       >> /root/.bashrc \
&&  echo 'PATH="${PATH}:/opt/questasim/RUVM_2021.2"'                                                        >> /root/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Matlab/R2022b/bin"'                                                            >> /root/.bashrc \
&&  echo 'PATH="${PATH}:$(find /opt/Xilinx/Vivado/* -maxdepth 0 -type d)/bin/unwrapped/lnx64.o"'            >> /root/.bashrc \
&&  echo 'PATH="${PATH}:$(find /opt/Xilinx/Vitis/* -maxdepth 0 -type d)/bin/unwrapped/lnx64.o"'             >> /root/.bashrc \
&&  echo 'PATH="${PATH}:$(find /opt/Xilinx/Vitis_HLS/* -maxdepth 0 -type d)/bin/unwrapped/lnx64.o"'         >> /root/.bashrc \
&&  echo 'alias vivado="vivado -log /tmp/vivado.log -journal /tmp/vivado.jou"'                              >> /root/.bashrc \
&&  echo 'export LM_LICENSE_FILE="/opt/questasim/license.dat"'                                              >> /root/.bashrc \
&&  echo 'export XILINXD_LICENSE_FILE="/opt/Xilinx/xilinx_vivado.lic"'                                      >> /root/.bashrc \
&&  echo 'export LD_PRELOAD="/lib/x86_64-linux-gnu/libudev.so.1"'                                           >> /root/.bashrc \
&&  echo 'source $(find /opt/Xilinx/Vivado/* -maxdepth 0 -type d)/settings64.sh'                            >> /root/.bashrc

# Duplicate host user
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash", "-l"]
