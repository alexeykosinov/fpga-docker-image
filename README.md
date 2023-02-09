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

Build:
```
docker build --build-arg VIVADO_TAR_HOST=10.77.11.172:8000 \
--build-arg VIVADO_TAR_FILE=Xilinx_Unified_2021.2_1021_0703 \
--build-arg VIVADO_TAR_UPDATE=Xilinx_Vivado_Vitis_Update_2021.2.1_1219_1431 \
--build-arg QUESTA_TAR_FILE=QuestaSim_2021.2.1_lin64 \
--build-arg VIVADO_VERSION=2021.2 \
--build-arg MATLAB_TAR_FILE=Matlab913Lin . -t vivado:2021.2
```

And run:
```
docker run --rm -it -t vivado:2021.2
```

For the tests run http server:
```
python3 -m http.server --bind 10.77.11.172
```
