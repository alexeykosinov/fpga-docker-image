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
