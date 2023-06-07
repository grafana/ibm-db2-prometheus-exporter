DOCKER_ARCHS ?= amd64
DOCKER_IMAGE_NAME ?= ibm-db2-exporter

ALL_SRC := $(shell find . -name '*.go' -o -name 'Dockerfile*' -type f | sort)

all:: vet common-all


include Makefile.common

