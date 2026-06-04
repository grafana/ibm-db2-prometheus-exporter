JSONNET_FMT := jsonnetfmt -n 2 --max-blank-lines 2 --string-style s --comment-style s
DOCKER_ARCHS ?= amd64 armv7 arm64
DOCKER_IMAGE_NAME ?= snowflake-exporter
GO_IBM_DB_VERSION := $(shell go list -m -f '{{.Version}}' github.com/ibmdb/go_ibm_db)
GOPATH := $(shell go env GOPATH)
CLIDRIVER_PATH := $(GOPATH)/pkg/mod/github.com/ibmdb/clidriver

# Override Makefile.common's default (v1.49.0); must be set before the include.
GOLANGCI_LINT_VERSION := v2.12.2
GOVULNCHECK_VERSION ?= 0782b76014f15f24e22a438f30f308df42899ba1 # v1.3.0
GOVULNCHECK          = $(FIRST_GOPATH)/bin/govulncheck

ALL_SRC := $(shell find . -name '*.go' -o -name 'Dockerfile*' -type f | sort)

all:: vet common-all security-check

.PHONY: exporter
exporter:
	go build -o ./bin/ibm_db2_exporter ./cmd/ibm-db2-exporter/main.go

include Makefile.common

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

# Check if .github/workflows/*.yml need to be updated
# when changing the install-ci-deps target.
install-ci-deps:
	go install github.com/google/go-jsonnet/cmd/jsonnet@v0.20.0
	go install github.com/google/go-jsonnet/cmd/jsonnetfmt@v0.20.0
	go install github.com/google/go-jsonnet/cmd/jsonnet-lint@v0.20.0
	go install github.com/monitoring-mixins/mixtool/cmd/mixtool@ea35232b9d85b4cd7943b481c6f90fd94f1ec0ca # no tagged release; pinned to main @ 2026-05-04
	go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@v0.5.1
	go install github.com/grafana/grizzly/cmd/grr@v0.7.1 # v0.7.1

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

.PHONY: vuln-check
vuln-check:
	@echo ">> Running govulncheck..."
	@command -v $(GOVULNCHECK) >/dev/null 2>&1 || { echo "govulncheck not installed. Install: go install golang.org/x/vuln/cmd/govulncheck@0782b76014f15f24e22a438f30f308df42899ba1 # v1.3.0"; exit 1; }
	$(GOVULNCHECK) ./...
	@echo ">> govulncheck passed!"

.PHONY: gosec-check
gosec-check: $(GOLANGCI_LINT)
	@echo ">> Running gosec via golangci-lint..."
	@command -v $(GOLANGCI_LINT) >/dev/null 2>&1 || { echo "golangci-lint not installed. Install: https://golangci-lint.run/docs/welcome/install/"; exit 1; }
	$(GOLANGCI_LINT) run --enable-only gosec $(pkgs)
	@echo ">> Security checks passed!"

.PHONY: security-check
security-check: vuln-check gosec-check
