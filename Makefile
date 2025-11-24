JSONNET_FMT := jsonnetfmt -n 2 --max-blank-lines 2 --string-style s --comment-style s
DOCKER_ARCHS ?= amd64 armv7 arm64
DOCKER_IMAGE_NAME ?= snowflake-exporter
GO_IBM_DB_VERSION := $(shell go list -m -f '{{.Version}}' github.com/ibmdb/go_ibm_db)
GOPATH := $(shell go env GOPATH)
CLIDRIVER_PATH := $(GOPATH)/pkg/mod/github.com/ibmdb/clidriver

ALL_SRC := $(shell find . -name '*.go' -o -name 'Dockerfile*' -type f | sort)

all:: vet common-all

.PHONY: exporter
exporter:
	go build -o ./bin/ibm_db2_exporter ./cmd/ibm-db2-exporter/main.go



.PHONY: install-db2-driver
install-db2-driver:
	@echo "Installing IBM DB2 driver (go_ibm_db version $(GO_IBM_DB_VERSION))..."
	go install github.com/ibmdb/go_ibm_db/installer@$(GO_IBM_DB_VERSION)
	@echo "Running DB2 clidriver setup..."
	cd $(GOPATH)/pkg/mod/github.com/ibmdb/go_ibm_db@$(GO_IBM_DB_VERSION)/installer && go run setup.go
	@echo ""
	@echo "Creating setenv.sh with DB2 driver environment variables..."
	@echo "#!/bin/bash" > setenv.sh
	@echo "# Source this file to set up DB2 driver environment variables" >> setenv.sh
	@echo "# e.g.: source setenv.sh" >> setenv.sh
	@echo "" >> setenv.sh
	@echo "export LD_LIBRARY_PATH=$(CLIDRIVER_PATH)/lib" >> setenv.sh
	@echo "export CGO_LDFLAGS=-L$(CLIDRIVER_PATH)/lib" >> setenv.sh
	@echo "export CGO_CFLAGS=-I$(CLIDRIVER_PATH)/include" >> setenv.sh
	@echo "export IBM_DB_HOME=$(CLIDRIVER_PATH)" >> setenv.sh
	@echo ""
	@echo "DB2 driver installation complete!"
	@echo "To rerun this command, run 'go clean -modcache' first, installation fails if the directory exists"
	@echo ""
	@echo "To compile the exporter, run:"
	@echo "  source ./setenv.sh && make exporter"

include Makefile.common

# Check if .github/workflows/*.yml need to be updated
# when changing the install-ci-deps target.
install-ci-deps:
	go install github.com/google/go-jsonnet/cmd/jsonnet@v0.20.0
	go install github.com/google/go-jsonnet/cmd/jsonnetfmt@v0.20.0
	go install github.com/google/go-jsonnet/cmd/jsonnet-lint@v0.20.0
	go install github.com/monitoring-mixins/mixtool/cmd/mixtool@main
	go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v0.5.1
	go install github.com/grafana/grizzly/cmd/grr@latest
	go install github.com/cloudflare/pint/cmd/pint@v0.70.0

fmt:
	@find . -name '*.libsonnet' -print -o -name '*.jsonnet' -print | \
			xargs -n 1 -- $(JSONNET_FMT) -i

lint-fmt:
	@RESULT=0; \
	for f in $$(find . -type f \( -name '*.libsonnet' -o -name '*.jsonnet' \) -not -path '*/vendor/*'); do \
			$(JSONNET_FMT) -- "$$f" | diff -u "$$f" -; \
			if [ $$? -ne 0 ]; then \
				RESULT=1; \
			fi; \
	done; \
	exit $$RESULT
