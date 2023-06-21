# **ibm-db2-prometheus-exporter**
Exports [IBM DB2](https://www.ibm.com/products/db2/database) metrics via HTTP for Prometheus consumption.

**Note:** This exporter is not compatible with ARM64 architectures due to restrictions with the driver.

# Prerequisites

The [go_ibm_db driver](https://github.com/ibmdb/go_ibm_db) needs installed C library files in order to connect to the database. A minimal setup could be provided via using the [clidriver](https://github.com/ibmdb/go_ibm_db/blob/master/installer/setup.go).

In order for DB2 to correctly report metric values, the database being monitored must be "explicitly activated". Doing so will make it so that certain metric values are correctly incremented and not periodically reset. However, it does result in a performance impact on the environment DB2 is running in. The size of this impact will depend on the system, but will result in the most accurate data reported by DB2 and, subsequently, this exporter. To explicitly activate a database, connect to DB2 and run the command `activate database <dbname>` and disconnect. Now DB2 will correctly increment and store metrics. 
```
db2
activate database sample
quit
```
To deactivate a database, connect to db2 and run the command `deactivate database <dbname>` and disconnect. Doing so will reset the metrics reported by DB2. The database must be reactivated in order for metrics to be properly incremented, stored, and reported by DB2.
**Note:** Whether or not the database is activated only affects DB2's ability to report metrics, it does not affect DB2's behavior as a database.

## Driver installation (optional)

```
go install github.com/ibmdb/go_ibm_db/installer@latest
```

Make sure to have the clidriver set up:
```
cd go/pkg/mod/github.com/ibmdb/go_ibm_db\@latest/installer && go run setup.go
```


## Required environment variables

Set the following environment variables before running the exporter in order for the driver to work:

```
LD_LIBRARY_PATH=go/pkg/mod/github.com/ibmdb/clidriver/lib
CGO_LDFLAGS=-L/usr/local/go/pkg/mod/github.com/ibmdb/tmp/clidriver/lib
CGO_CFLAGS=-I/usr/local/go/pkg/mod/github.com/ibmdb/clidriver/include
```

# Configuration

You can build a binary of the exporter by running `make exporter` in this directory.

**Note:** This exporter only connects to a single database. To monitor multiple databases, each one will need an exporter.
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

Example usage:
```
./ibm_db2_exporter --db="database" --dsn="DATABASE=database;HOSTNAME=localhost;PORT=50000;UID=user;PWD=password;"
```
**Note:**
  - `--dsn` and `--db` are required flags, if not set as environment variables.
  - This exporter does not verify DSN strings. If you have trouble connecting, make sure the DSN is configured correctly.

## Environment Variables:

You can also set the DSN and DB as environment variables and then run the exporter:  
```
IBM_DB2_EXPORTER_DSN="DATABASE=database;HOSTNAME=localhost;PORT=50000;UID=user;PWD=password;"  
IBM_DB2_EXPORTER_DB="database"  

./ibm_db2_exporter
```
