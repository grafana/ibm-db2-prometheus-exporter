# **ibm-db2-prometheus-exporter**
Exports [IBM DB2](https://www.ibm.com/products/db2/database?utm_content=SRCWW&p1=Search&p4=43700074899141970&p5=e&gclid=CjwKCAjw1YCkBhAOEiwA5aN4ARNs41KBBnhWj6dwPb2TECYFb3E_InKMe6mdSMBIPqJ4NWPsoqyIuRoCQmkQAvD_BwE&gclsrc=aw.ds) metrics via HTTP for Prometheus consumption.

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
      --[no-]version             Show application version.
      --log.level=info           Only log messages with the given severity or above. One of: [debug, info, warn,
                                 error]
      --log.format=logfmt        Output format of log messages. One of: [logfmt, json]
```

Example usage:
```
./ibm_db2_exporter --dsn="DATABASE=database;HOSTNAME=localhost;PORT=50000;UID=user;PWD=password;"
```
## Environment Variables:

You can also set the DSN as an environment variable and then run the exporter:  
```
IBM_DB2_EXPORTER_DSN="DATABASE=database;HOSTNAME=localhost;PORT=50000;UID=user;PWD=password;"  

./ibm_db2_exporter
```
