# syntax=docker/dockerfile:1
FROM golang:1.20 as build
ARG IBM_DB_VER=v0.4.4

RUN go install github.com/ibmdb/go_ibm_db/installer@${IBM_DB_VER}
RUN cd /go/pkg/mod/github.com/ibmdb/go_ibm_db@${IBM_DB_VER}/installer && go run setup.go

ENV LD_LIBRARY_PATH=/go/pkg/mod/github.com/ibmdb/clidriver/lib
ENV CGO_LDFLAGS=-L/go/pkg/mod/github.com/ibmdb/clidriver/lib
ENV CGO_CFLAGS=-I/go/pkg/mod/github.com/ibmdb/clidriver/include

WORKDIR /src
ADD . /src/
RUN make exporter

FROM ubuntu:jammy
RUN apt-get update && apt-get install -y libxml2 && apt-get clean
COPY --from=build /src/bin/ibm_db2_exporter /bin/ibm_db2_exporter
COPY --from=build /go/pkg/mod/github.com/ibmdb/clidriver/lib /usr/lib/
ENTRYPOINT ["/bin/ibm_db2_exporter"]
