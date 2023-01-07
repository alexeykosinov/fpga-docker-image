SHELL := /bin/bash

IMAGE_NAME:=vivado
DOWNLOAD_HOST:=10.77.11.172:8000
BUILD_VIVADO_TAR_F:=Xilinx_Unified_2021.2_1021_0703
BUILD_VIVADO_TAR_U:=Xilinx_Vivado_Vitis_Update_2021.2.1_1219_1431
BUILD_QUESTA_TAR_F:=QuestaSim_2021.2.1_lin64
VIVADO_VER:=2021.2

build:
	@docker build --build-arg VIVADO_TAR_HOST=$(DOWNLOAD_HOST) \
		--build-arg VIVADO_TAR_FILE=$(BUILD_VIVADO_TAR_F) \
		--build-arg VIVADO_TAR_UPDATE=$(BUILD_VIVADO_TAR_U) \
		--build-arg QUESTA_TAR_FILE=$(BUILD_QUESTA_TAR_F) \
		--build-arg VIVADO_VERSION=$(VIVADO_VER) \
		. \
		-t $(IMAGE_NAME):$(VIVADO_VER)

run:
	@docker run \
		-w /var/lib/jenkins/workspace/test_vivado \
		-v /var/lib/jenkins/workspace/test_vivado:/var/lib/jenkins/workspace/test_vivado:rw,z \
		-v /var/lib/jenkins/workspace/test_vivado@tmp:/var/lib/jenkins/workspace/test_vivado@tmp:rw,z \
		--rm \
		-t \
		--init \
		-it $(IMAGE_NAME):$(VIVADO_VER)

clean:
	@docker system prune -a

.PHONY: build run clean