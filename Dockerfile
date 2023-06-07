ARG ARCH="amd64"
ARG OS="linux"
FROM quay.io/prometheus/busybox-${OS}-${ARCH}:latest

ARG ARCH="amd64"
ARG OS="linux"
COPY .build/${OS}-${ARCH}/ibm-db2-exporter /bin/ibm-db2-exporter

EXPOSE      9953
USER        nobody
ENTRYPOINT  [ "/bin/ibm-db2-exporter" ]
