# IBM DB2 Mixin

The IBM DB2 mixin consists of a configurable Grafana dashboard and alerts based on the [IBM DB2 exporter](../README.md).


The IBM DB2 mixin contains the following dashboards:

- IBM DB2 overview

The mixin also contains the following alerts:

- IBMDB2HighLockWaitTime
- IBMDB2HighNumberOfDeadlocks
- IBMDB2LogUsageReachingLimit

Default thresholds can be configured in `config.libsonnet`.

```js
{
    _config+:: {
        alertsHighLockWaitTime: 2000,    //ms
        alertsHighNumberOfDeadlocks: 5,  //count
        alertsLogUsageReachingLimit: 90, //percent 0-100
    },
}
```

## IBM DB2 overview
The IBM DB2 overview dashboard provides details about the general state of the database like bufferpool hit ratio, active connections, and deadlocks.

![First screenshot of the overview dashboard](https://storage.googleapis.com/grafanalabs-integration-assets/ibm-db2/screenshots/ibm-db2-overview-1.png)
![Second screenshot of the overview dashboard](https://storage.googleapis.com/grafanalabs-integration-assets/ibm-db2/screenshots/ibm-db2-overview-2.png)

## Logs
To get IBM DB2 diagnostic logs, [Promtail and Loki needs to be installed](https://grafana.com/docs/loki/latest/installation/) and provisioned for logs with your Grafana instance. The default location of the diagnostic log file depends on the instance of DB2 the database being monitored is in. For single member instances, the location will look like something like this path(depends on where your instance of DB2 is located) `/home/*/sqllib/db2dump/db2diag.log`. For other instances of DB2, the path to the logs file will look like `/home/*/sqllib/db2dump/DIAG*/db2diag.log`. `DIAG*` represents any number of directories that may be present at that level that each contain a log file.

IBM DB2 diagnostic logs are enabled by default in the `config.libsonnet` and can be removed by setting `enableLokiLogs` to `false`. Then run `make` again to regenerate the dashboard:

```js
{
    _config+:: {
        enableLokiLogs: false
    },
}
```

## Alerts Overview
- IBMDB2HighLockWaitTime: The average wait time for a lock in the database is high.
- IBMDB2HighNumberOfDeadlocks: The number of deadlocks occurring in the database is high.
- IBMDB2LogUsageReachingLimit: The amount of log space available for the DB2 instance is running out of space.



## Install tools
```bash
go install github.com/jsonnet-bundler/jsonnet-bundler/cmd/jb@latest
go install github.com/monitoring-mixins/mixtool/cmd/mixtool@latest
```

For linting and formatting, you would also need and `jsonnetfmt` installed. If you
have a working Go development environment, it's easiest to run the following:

```bash
go install github.com/google/go-jsonnet/cmd/jsonnetfmt@latest
```

The files in `dashboards_out` need to be imported
into your Grafana server. The exact details will be depending on your environment.

`prometheus_alerts.yaml` needs to be imported into Prometheus.

## Generate dashboards and alerts

Edit `config.libsonnet` if required and then build JSON dashboard files for Grafana:

```bash
make
```

For more advanced uses of mixins, see
https://github.com/monitoring-mixins/docs.