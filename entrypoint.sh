#!/bin/bash

USER=${USER:-root}
USER_ID=${LOCAL_UID:-1000}
GROUP_ID=${LOCAL_GID:-1000}

echo "Starting with UID: $USER_ID, GID: $GROUP_ID, USER: $USER"

if [[ -n "$USER_ID" ]]; then
    # Check if there is some kinky username with the domain
    if grep -q "@" <<< "$USER"; then
        export HOME=/home/${USER#*@}/${USER%%@*}
    else
        export HOME=/home/$USER
    fi

    useradd -s /bin/bash -u $USER_ID -o -d $HOME $USER
    usermod -aG sudo $USER
    echo ${USER}:jenkins | chpasswd
    chown $USER_ID:$GROUP_ID -R $HOME

    # Add tools path, env & etc.
    export PATH="${PATH}:/opt/questasim/linux_x86_64"
    export PATH="${PATH}:/opt/questasim/RUVM_2021.2"
    export PATH="${PATH}:/opt/Matlab/R2022b/bin"
    export PATH="${PATH}:$(find /opt/Xilinx/Vivado/* -maxdepth 0 -type d)/bin/unwrapped/lnx64.o"
    export PATH="${PATH}:$(find /opt/Xilinx/Vitis/* -maxdepth 0 -type d)/bin/unwrapped/lnx64.o"
    export PATH="${PATH}:$(find /opt/Xilinx/Vitis_HLS/* -maxdepth 0 -type d)/bin/unwrapped/lnx64.o"
    export LM_LICENSE_FILE="/opt/questasim/license.dat"
    export XILINXD_LICENSE_FILE="/opt/Xilinx/xilinx_vivado.lic"
    export LD_PRELOAD="/lib/x86_64-linux-gnu/libudev.so.1"
    # export XILINX="${XILINX}:/opt/Xilinx"

    # For Vitis HLS probably need to export
    # (but need to avoid that or temporary export coz it's damaged Vitis somehow)
    # export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu

    alias vivado="vivado -log /tmp/vivado.log -journal /tmp/vivado.jou"
    source $(find /opt/Xilinx/Vivado/* -maxdepth 0 -type d)/settings64.sh

    # Generate Questa Sim license on the fly
    echo "Generate Questa SIM-64 license file"
    pushd /tmp && python2 /opt/mgclicgen.py $(cat /sys/class/net/eth0/address | tr -d ":") && popd
    mv /tmp/license.dat /opt/questasim/

    exec /usr/sbin/gosu "$USER" "$@"
else
    exec "$@"
fi
