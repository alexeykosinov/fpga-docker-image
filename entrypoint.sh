#!/bin/bash

echo "Execute environment script"

# Add tools path, env & etc.
# export PATH="${PATH}:/opt/questasim/linux_x86_64"
# export PATH="${PATH}:/opt/questasim/RUVM_2021.2"
# export PATH="${PATH}:/opt/Matlab/R2022b/bin"
# export PATH="${PATH}:$(find /opt/Xilinx/Vivado/* -maxdepth 0 -type d)/bin/unwrapped/lnx64.o"
# export PATH="${PATH}:$(find /opt/Xilinx/Vitis/* -maxdepth 0 -type d)/bin/unwrapped/lnx64.o"
# export PATH="${PATH}:$(find /opt/Xilinx/Vitis_HLS/* -maxdepth 0 -type d)/bin/unwrapped/lnx64.o"
# export LM_LICENSE_FILE="/opt/questasim/license.dat"
# export XILINXD_LICENSE_FILE="/opt/Xilinx/xilinx_vivado.lic"
# export LD_PRELOAD="/lib/x86_64-linux-gnu/libudev.so.1"
# export XILINX="${XILINX}:/opt/Xilinx"

# For Vitis HLS probably need to export
# (but need to avoid that or temporary export coz it's damaged Vitis somehow)
# export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu

# alias vivado="vivado -log /tmp/vivado.log -journal /tmp/vivado.jou"
# source $(find /opt/Xilinx/Vivado/* -maxdepth 0 -type d)/settings64.sh

# Generate Questa Sim license on the fly
pushd /tmp > /dev/null && python2 /opt/mgclicgen.py $(cat /sys/class/net/eth0/address | tr -d ":") && popd > /dev/null
mv /tmp/license.dat /opt/questasim/

exec /usr/sbin/gosu "$USER" "$@"
