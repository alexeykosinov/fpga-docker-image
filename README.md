## 1. Setting up Xilinx installer

### Generate Xilinx silent installation configuration file (~/.Xilinx/install_config.txt) for Vivado and Vitis

```
xsetup -b ConfigGen
```

### Batch mode installation

```
xsetup --agree XilinxEULA,3rdPartyEULA,WebTalkTerms --batch Install --config install_config.txt
```

## 2. Docker file

```
sudo docker build --build-arg VIVADO_TAR_HOST=10.77.11.172:8000 --build-arg VIVADO_TAR_FILE=Xilinx_Unified_2021.2_1021_0703 --build-arg VIVADO_VERSION=2021.2 . -t vivado:2021.2
```


