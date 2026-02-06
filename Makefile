# Makefile for Debian Docker Desktop
.PHONY: all build build-kasmvnc build-selkies clean prepare help

# Default configuration
USERNAME ?= user
IMAGE_TAG ?= latest

# Image names
KASMVNC_IMAGE = debian-desktop:kasmvnc-$(IMAGE_TAG)
SELKIES_IMAGE = debian-desktop:selkies-$(IMAGE_TAG)

all: build

help:
	@echo "Debian Docker Desktop Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build          - Build all images"
	@echo "  build-kasmvnc  - Build KasmVNC variant"
	@echo "  build-selkies  - Build Selkies variant"
	@echo "  run-kasmvnc    - Run KasmVNC container"
	@echo "  run-selkies    - Run Selkies container"
	@echo "  stop           - Stop all containers"
	@echo "  clean          - Remove built images"
	@echo "  prepare        - Prepare build contexts"
	@echo "  help           - Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  USERNAME       - Desktop username (default: user)"
	@echo "  IMAGE_TAG      - Image tag (default: latest)"

# Prepare build contexts by copying shared scripts
prepare:
	@echo "Preparing build contexts..."
	@cp docker/base/scripts/env-setup.sh docker/kasmvnc/scripts/
	@cp docker/base/scripts/init-user.sh docker/kasmvnc/scripts/
	@cp docker/base/scripts/plugin-manager.sh docker/kasmvnc/scripts/
	@cp docker/base/scripts/env-setup.sh docker/selkies/scripts/
	@cp docker/base/scripts/init-user.sh docker/selkies/scripts/
	@cp docker/base/scripts/plugin-manager.sh docker/selkies/scripts/
	@echo "Build contexts prepared."

build: build-kasmvnc build-selkies

build-kasmvnc: prepare
	@echo "Building KasmVNC image..."
	docker build \
		--build-arg USERNAME=$(USERNAME) \
		-t $(KASMVNC_IMAGE) \
		-f docker/kasmvnc/Dockerfile \
		docker/kasmvnc/
	@echo "KasmVNC image built: $(KASMVNC_IMAGE)"

build-selkies: prepare
	@echo "Building Selkies image..."
	docker build \
		--build-arg USERNAME=$(USERNAME) \
		-t $(SELKIES_IMAGE) \
		-f docker/selkies/Dockerfile \
		docker/selkies/
	@echo "Selkies image built: $(SELKIES_IMAGE)"

run-kasmvnc:
	@echo "Starting KasmVNC container..."
	docker compose -f docker-compose.kasmvnc.yml up -d
	@echo "KasmVNC desktop available at http://localhost:6901"

run-selkies:
	@echo "Starting Selkies container..."
	docker compose -f docker-compose.selkies.yml up -d
	@echo "Selkies desktop available at http://localhost:8080"

stop:
	@echo "Stopping containers..."
	-docker compose -f docker-compose.kasmvnc.yml down
	-docker compose -f docker-compose.selkies.yml down
	@echo "Containers stopped."

clean: stop
	@echo "Removing images..."
	-docker rmi $(KASMVNC_IMAGE)
	-docker rmi $(SELKIES_IMAGE)
	@echo "Cleanup complete."

logs-kasmvnc:
	docker compose -f docker-compose.kasmvnc.yml logs -f

logs-selkies:
	docker compose -f docker-compose.selkies.yml logs -f

shell-kasmvnc:
	docker compose -f docker-compose.kasmvnc.yml exec desktop bash

shell-selkies:
	docker compose -f docker-compose.selkies.yml exec desktop bash
