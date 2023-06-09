all:: vet common-all

.PHONY: exporter
exporter: 
	go build -o ./bin/ibm_db2_exporter ./cmd/ibm-db2-exporter/main.go

include Makefile.common
