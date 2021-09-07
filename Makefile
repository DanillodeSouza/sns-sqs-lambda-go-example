.PHONY: usage build build-binary lint zip start start-detached stop update-lambda

OK_COLOR=\033[32;01m
NO_COLOR=\033[0m
ERROR_COLOR=\033[31;01m

GO := go
GO_LINTER := golint
GOFLAGS ?=
ECHOFLAGS ?=
ROOT_DIR := $(realpath .)
DOCKER := docker
DOCKER_COMPOSE := docker-compose
DOCKER_EXISTS := $(shell type $(DOCKER) > /dev/null 2> /dev/null; echo $$? )

LOCAL_VARIABLES ?= $(shell while read -r line; do printf "$$line" | sed 's/ /\\ /g' | awk '{print}'; done < $(ROOT_DIR)/.env)

PKGS = $(shell $(GO) list ./...)

## usage: show available actions
usage: Makefile
	@echo "to use make call:"
	@echo "make <action>"
	@echo ""
	@echo "list of available actions:"
	@sed -n 's/^##//p' $< | column -t -s ':' | sed -e 's/^/ /'

## zip: create a new zip for lambda api
zip:
	@echo "$(OK_COLOR)==> Zipping binary (linux/amd64/lambda-example)...$(NO_COLOR)"
	cd bin/linux_amd64 && zip lambda-example.zip lambda-example

## build: build all
build: build-binary zip

## build-binary: build GO binary
build-binary:
	@echo "$(OK_COLOR)==> Building binary (linux/amd64/lambda-example)...$(NO_COLOR)"
	@echo GOOS=linux GOARCH=amd64 $(GO) build -v -o bin/linux_amd64/lambda-example ./cmd/lambda-example
	@GOOS=linux GOARCH=amd64 $(GO) build -v $(BUILDFLAGS) -o bin/linux_amd64/lambda-example ./cmd/lambda-example


## start: start compose
up: build
	@echo $(ECHOFLAGS) "$(OK_COLOR)==> Starting docker compose...$(NO_COLOR)"
	docker-compose up --build

## start-detached: start compose in detached mode (background)
start-detached: build
	@echo $(ECHOFLAGS) "$(OK_COLOR)==> Starting docker compose in detached mode...$(NO_COLOR)"
	docker-compose up --build -d

## update-lambda: Update lambda code
update-lambda: build zip
	@echo "$(OK_COLOR)==> Updating lambda code...$(NO_COLOR)"
	sh ./scripts/update-lambda.sh
	@echo "$(OK_COLOR)==> Lambda updated...$(NO_COLOR)"

## stop: stop compose
down:
	@echo $(ECHOFLAGS) "$(OK_COLOR)==> Stopping docker compose...$(NO_COLOR)"
	@ROOT_DIR=$(ROOT_DIR) $(DOCKER_COMPOSE) down --rmi local --remove-orphan -t 10
