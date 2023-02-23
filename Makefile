SHELL := /bin/bash

IMAGE_NAME:=vivado
DOWNLOAD_HOST:=msk-fs-dfs-03
TECH_USER:=DFS_local
TECH_PWD:=8D5yyP9x
BUILD_VIVADO_TAR_F:=Xilinx_Unified_2021.2_1021_0703
BUILD_VIVADO_TAR_U:=Xilinx_Vivado_Vitis_Update_2021.2.1_1219_1431
BUILD_QUESTA_TAR_F:=QuestaSim_2021.2.1_lin64
BUILD_MATLAB_TAR_F:=Matlab913Lin
VIVADO_VER:=2021.2

build:
	@docker build \
		--build-arg SMB_HOST=$(DOWNLOAD_HOST) \
		--build-arg SMB_USER=$(TECH_USER) \
		--build-arg SMB_PWD=$(TECH_PWD) \
		--build-arg VIVADO_TAR_FILE=$(BUILD_VIVADO_TAR_F) \
		--build-arg VIVADO_TAR_UPDATE=$(BUILD_VIVADO_TAR_U) \
		--build-arg QUESTA_TAR_FILE=$(BUILD_QUESTA_TAR_F) \
		--build-arg MATLAB_TAR_FILE=$(BUILD_MATLAB_TAR_F) \
		--build-arg VIVADO_VERSION=$(VIVADO_VER) \
		. \
		-t $(IMAGE_NAME):$(VIVADO_VER)

run:
	@docker run \
		--rm \
		-t \
		--init \
		-it \
		$(IMAGE_NAME):$(VIVADO_VER)

clean:
	@docker rmi $(docker images -q $(IMAGE_NAME))

.PHONY: build run clean