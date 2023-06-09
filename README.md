# **ibm-db2-prometheus-exporter**
Exports [IBM DB2](https://www.ibm.com/products/db2/database?utm_content=SRCWW&p1=Search&p4=43700074899141970&p5=e&gclid=CjwKCAjw1YCkBhAOEiwA5aN4ARNs41KBBnhWj6dwPb2TECYFb3E_InKMe6mdSMBIPqJ4NWPsoqyIuRoCQmkQAvD_BwE&gclsrc=aw.ds) metrics via HTTP for Prometheus consumption.

# Prerequisites

The [go_ibm_db driver](https://github.com/ibmdb/go_ibm_db) needs installed C library files in order to connect to the database. A minimal setup could be provided via using the [clidriver](https://github.com/ibmdb/go_ibm_db/blob/master/installer/setup.go).
```
go install github.com/ibmdb/go_ibm_db/installer@latest
```

Make sure to have the clidriver set up:
```
cd go/pkg/mod/github.com/ibmdb/go_ibm_db\@latest/installer && go run setup.go
```

Set the following environment variables before running the exporter:
```
LD_LIBRARY_PATH=go/pkg/mod/github.com/ibmdb/clidriver/lib
CGO_LDFLAGS=-L/usr/local/go/pkg/mod/github.com/ibmdb/tmp/clidriver/lib
CGO_CFLAGS=-I/usr/local/go/pkg/mod/github.com/ibmdb/clidriver/include
```

# Configuration

You can build a binary of the exporter by running `make exporter` in this directory.
## Command line flags

The exporter may be configured through its command line flags (run with -h to see options):
```
  -h, --[no-]help                Show context-sensitive help (also try --help-long and --help-man).
      --[no-]web.systemd-socket  Use systemd socket activation listeners instead of port listeners (Linux only).
      --web.listen-address=:9953 ...
                                 Addresses on which to expose metrics and web interface. Repeatable for multiple
                                 addresses.
      --web.config.file=""       [EXPERIMENTAL] Path to configuration file
                                 that can enable TLS or authentication. See:
                                 https://github.com/prometheus/exporter-toolkit/blob/master/docs/web-configuration.md
      --web.telemetry-path="/metrics"
                                 Path under which to expose metrics. ($IBM_DB2_EXPORTER_WEB_TELEMETRY_PATH)
      --dsn=DSN                  The connection string (data source name) to use to connect to the database when
                                 querying metrics. ($IBM_DB2_EXPORTER_DSN)
      --db=DB                    The database to connect to when querying metrics. ($IBM_DB2_EXPORTER_DB)
      --[no-]version             Show application version.
      --log.level=info           Only log messages with the given severity or above. One of: [debug, info, warn,
                                 error]
      --log.format=logfmt        Output format of log messages. One of: [logfmt, json]
```
**Note:** `--dsn` and `--db` are required flags, if not set as environment variables.

Example usage:
```
./ibm_db2_exporter --db="database" --dsn="DATABASE=database;HOSTNAME=localhost;PORT=50000;UID=user;PWD=password;"
```

Note that this exporter does not verify DSN strings, if you have trouble connecting, make sure your DSN is configured correctly. 
## Environment Variables:

You can also set the DSN and DB as environment variables and then run the exporter:  
```
IBM_DB2_EXPORTER_DSN="DATABASE=database;HOSTNAME=localhost;PORT=50000;UID=user;PWD=password;"  
IBM_DB2_EXPORTER_DB="database"  

./ibm_db2_exporter
```
