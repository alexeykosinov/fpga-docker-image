# Whats included:
- Xilinx Design Tools 2021.2.1 (Vivado, Vitis, Vitis HLS)
- Siemens (Mentor Graphics) Questa Sim-64 2021.1
- Matlab R2022b
- Python 3.9

# Checklist
- [x] Building Vivado projects (PL)
- [x] Building Vitis projects (PS)
- [x] Building Vitis HLS projects
- [x] Matlab support
- [x] Running multiple copy of image on the single host
- [x] Questa Sim precompiled Xilinx libraries from the box
- [x] Questa Sim rtl simulation
- [ ] Questa Sim rtl simulation with UVM
- [ ] Questa Sim rtl simulation with DPI support
- [x] cocotb support
- [x] compatibility with Jenkins
- [x] port forwarding (for remote uploading firmware)

# Setting up

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
