## Whats included:
- Xilinx Vivado 2021.2.1 (Vitis, Vitis HLS)
- Siemens (Mentor Graphics) Questa Sim-64 2021.1
- Matlab R2022b
- Python 3.9

## Checklist
- [x] Building Vivado projects (PL)
- [x] Building Vitis projects (PS)
- [x] Building Vitis HLS projects
- [x] Matlab support
- [x] Running multiple copy of image on the single host
- [x] Questa Sim precompiled Xilinx libraries from the box
- [x] Questa Sim rtl simulation
- [-] Questa Sim rtl simulation with UVM
- [-] Questa Sim rtl simulation with DPI support
- [-] cocotb support
- [-] compatibility with Jenkins
- [+] port forwarding (for remote uploading firmware)

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

Building:
```
make build
```

Running:
```
make run
```

And cleaning:
```
make clean
```

For the tests run http server:
```
python3 -m http.server --bind 10.77.11.172
```
