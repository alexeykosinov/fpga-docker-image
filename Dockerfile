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
    # dbus-x11 \
    xvfb \
    curl \
    python3.9 \
    python3.9-distutils \
    python3.9-dev \
&&  apt-get clean \
&&  rm -rf /var/lib/apt/lists/*



# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN adduser --disabled-password --uid 1002 --shell /bin/bash --gecos '' jenkins

# Get MAC Address (used for the license)
ARG HOST_ID="cat /sys/class/net/eth0/address | tr -d ':'"

# Xilinx License dir
ADD license /opt
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
&& cat /tmp/matlab.log \
&& cp libmwlmgrimpl.so /opt/Matlab/R2022b/bin/glnxa64/matlab_startup_plugins/lmgrimpl \
&& rm -rf ${MATLAB_TAR_FILE}

# Download and run the installation of Questa Sim
RUN cd /opt \
&&  smbget smb://${SMB_HOST}/Distrib/Engineering/Siemens/${QUESTA_TAR_FILE}.tar.gz -U "${SMB_USER}%${SMB_PWD}" -v \
&&  pv -f ${QUESTA_TAR_FILE}.tar.gz | tar -xzf - --directory . \
&&  rm -rf ${QUESTA_TAR_FILE}.tar.gz \
&&  cd ${QUESTA_TAR_FILE} \
&&  cp mgclicgen.py /opt \
&&  cd .. \
&&  chmod +x questa_install.sh \
&&  ./questa_install.sh -tgt /opt -msiloc /home/jenkins \
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
&& update-alternatives --config python3 \
&& curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py \
&& python3 get-pip.py \
&& python3 -m pip install /opt/Matlab/R2022b/extern/engines/python/ \
&& pip3 install libpython

# Add tools path, env & etc.
RUN echo 'PATH="${PATH}:/opt/questasim/linux_x86_64"'                                                       >> /home/jenkins/.bashrc \
&&  echo 'PATH="${PATH}:/opt/questasim/RUVM_2021.2"'                                                        >> /home/jenkins/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Matlab/R2022b/bin"'                                                            >> /home/jenkins/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Xilinx/Vivado/2021.2/bin/unwrapped/lnx64.o"'                                   >> /home/jenkins/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Xilinx/Vitis/2021.2/bin/unwrapped/lnx64.o"'                                    >> /home/jenkins/.bashrc \
&&  echo 'PATH="${PATH}:/opt/Xilinx/Vitis_HLS/2021.2/bin/unwrapped/lnx64.o"'                                >> /home/jenkins/.bashrc \
&&  echo 'export LM_LICENSE_FILE="/opt/questasim/license.dat"'                                              >> /home/jenkins/.bashrc \
&&  echo 'export XILINXD_LICENSE_FILE="/opt/Xilinx/xilinx_vivado.lic"'                                      >> /home/jenkins/.bashrc \
&&  echo 'export LD_PRELOAD=/lib/x86_64-linux-gnu/libudev.so.1'                                             >> /home/jenkins/.bashrc \
&&  echo 'XILINX="${XILINX}:/opt/Xilinx"'                                                                   >> /home/jenkins/.bashrc \
&&  echo 'alias vivado="vivado -log /tmp/vivado.log -journal /tmp/vivado.jou"'                              >> /home/jenkins/.bashrc \
&&  echo "source /opt/Xilinx/Vivado/${VIVADO_VERSION}/settings64.sh"                                        >> /home/jenkins/.bashrc

RUN echo 'PATH="${PATH}:/home/jenkins/.local/bin"'                                                          >> /home/jenkins/.profile \
&&  echo 'PATH="${PATH}:/tmp/bin"'                                                                          >> /home/jenkins/.profile \
&&  echo 'pushd /tmp && python2 /opt/mgclicgen.py $(cat /sys/class/net/eth0/address | tr -d ":") && popd'   >> /home/jenkins/.profile \
&&  echo 'mv /tmp/license.dat /opt/questasim/'                                                              >> /home/jenkins/.profile



# Copy Xilinx license file
COPY license/*.lic /opt/Xilinx/

# Not really necessary, just to make it easier to install packages on the run...
RUN echo "root:docker" | chpasswd

SHELL ["/bin/bash", "-c"]

RUN cd /opt/questasim/gcc-5.3.0-linux_x86_64/libexec/gcc/x86_64-unknown-linux-gnu/5.3.0/ \
&&  rm ld && ln -s /usr/bin/ld ld && cd /opt \
&&  . /home/jenkins/.profile \
&&  vivado -nojournal -notrace -mode batch -source /opt/compile_sim.tcl

USER jenkins

