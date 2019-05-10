PROJECT ?= elastic-rails
DOCKER_COMPOSE_FILE ?= docker-compose.services.yml
DOCKER_COMPOSE_ARGS ?= -p $(PROJECT) -f $(DOCKER_COMPOSE_FILE)
SHELL := /bin/bash

run: help

BOLD ?= $(shell tput bold)
NORMAL ?= $(shell tput sgr0)

help:
	@echo Run elasticsearch for development:
	@echo "  ${BOLD}make services-up${NORMAL}"
	@echo ""
	@echo "Reset the environment:"
	@echo "  ${BOLD}make services-destroy${NORMAL}"
	@echo ""

run: services-up

services-ps:
	docker-compose $(DOCKER_COMPOSE_ARGS) ps

services-up:
	docker-compose $(DOCKER_COMPOSE_ARGS) up -d

services-stop:
	docker-compose $(DOCKER_COMPOSE_ARGS) stop

services-destroy:
	docker-compose $(DOCKER_COMPOSE_ARGS) down --volumes

services-logs:
	docker-compose $(DOCKER_COMPOSE_ARGS) logs -f

services-port:
	@set -o pipefail; \
	docker-compose $(DOCKER_COMPOSE_ARGS) port ${SERVICE} ${PORT} 2> /dev/null | cut -d':' -f2 || echo ${PORT}
