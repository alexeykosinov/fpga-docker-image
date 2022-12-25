#!/bin/bash

usage() {
cat << EOF
usage: $0 options

This script can communicate with TI-S-349A via COM port.

OPTIONS:

    -h  Show this message
    -d  [DIR] Path to the installer
    -c  [1] Vivado; [2] Vitis
    -o  Future use

EOF
}

XILINX_TAR_FILE="UNDEFINED"


while getopts "hd:c:o" OPTION
do
    case $OPTION in
        h) usage exit ;;
        d)
            if [ -d "$OPTARG" ]; then
                echo "$OPTARG directory exists, go to the next step"
                XILINX_TAR_FILE=$OPTARG
            else
                echo "[ ERROR ] Directory doesn't exist"
                exit
            fi
            ;;
        c)
            if [ "$OPTARG" == "1" ]; then
                echo "[ INFO  ] Xilinx Vivado installation begins..."
                echo "[ INFO  ] tar file: ${XILINX_TAR_FILE}"
                #/opt/${XILINX_TAR_FILE}/xsetup --agree XilinxEULA,3rdPartyEULA,WebTalkTerms --batch Install --config /opt/install_config/vivado.txt
            elif [ "$OPTARG" == "2" ]; then
                echo "[ INFO  ] Xilinx Vitis installation begins..."
                echo "[ INFO  ] tar file: ${XILINX_TAR_FILE}"
                #/opt/${XILINX_TAR_FILE}/xsetup --agree XilinxEULA,3rdPartyEULA,WebTalkTerms --batch Install --config /opt/install_config/vitis.txt
            else
                echo "[ ERROR ] Wrong command"
                exit
            fi
            ;;
        o)
            echo "[ OK    ] Future use"
            ;;
        ?)
            echo "[ ERROR ] Wrong argument"
            exit
            ;;
    esac
done