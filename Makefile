DOCKER_ARCHS ?= amd64
DOCKER_IMAGE_NAME ?= ibm-db2-exporter

ALL_SRC := $(shell find . -name '*.go' -o -name 'Dockerfile*' -type f | sort)

all:: vet common-all

.PHONY: exporter
exporter: 
	go build -o ./bin/ibm_db2_exporter ./cmd/ibm-db2-exporter/main.go

include Makefile.common

