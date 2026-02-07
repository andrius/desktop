# Makefile for Debian Docker Desktop
.PHONY: all build clean prepare help run stop logs shell test-plugins

# Default configuration
USERNAME ?= user
IMAGE_TAG ?= latest

# Image name
IMAGE_NAME = desktop:$(IMAGE_TAG)

all: build

help:
	@echo "Debian Docker Desktop Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build          - Build the image"
	@echo "  run            - Run the container"
	@echo "  stop           - Stop the container"
	@echo "  logs           - Follow container logs"
	@echo "  shell          - Shell into running container"
	@echo "  clean          - Remove built images"
	@echo "  prepare        - Prepare build context"
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
	@cp docker/base/scripts/plugin-lib.sh docker/kasmvnc/scripts/
	@cp docker/base/scripts/setup-user.sh docker/kasmvnc/scripts/
	@rm -rf docker/kasmvnc/plugins/
	@cp -r plugins/ docker/kasmvnc/plugins/
	@echo "Build contexts prepared."

build: prepare
	@echo "Building image..."
	docker build \
		--build-arg USERNAME=$(USERNAME) \
		-t $(IMAGE_NAME) \
		-f docker/kasmvnc/Dockerfile \
		docker/kasmvnc/
	@echo "Image built: $(IMAGE_NAME)"

run:
	@echo "Starting container..."
	docker compose up -d
	@echo "Desktop available at http://localhost:6901"

stop:
	@echo "Stopping containers..."
	-docker compose down
	@echo "Containers stopped."

clean: stop
	@echo "Removing images..."
	-docker rmi $(IMAGE_NAME)
	@echo "Cleanup complete."

logs:
	docker compose logs -f

shell:
	docker compose exec desktop bash

test-plugins:
	@chmod +x scripts/test-plugins.sh
	@./scripts/test-plugins.sh $(ARGS)
