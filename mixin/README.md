# IBM DB2 Mixin

The IBM DB2 mixin consists of a configurable Grafana dashboard and alerts based on the [IBM DB2 exporter](../README.md).

The IBM DB2 mixin contains the following dashboards:
- IBM DB2 overview

## IBM DB2 overview
The IBM DB2 overview dashboard provides details about the general state of the database like bufferpool hit ratio, active connections, and deadlocks.

![First screenshot of the overview dashboard](https://storage.googleapis.com/grafanalabs-integration-assets/snowflake/screenshots/ibm_db2_overview_1.png)
![Second screenshot of the overview dashboard](https://storage.googleapis.com/grafanalabs-integration-assets/snowflake/screenshots/ibm_db2_overview_2.png)

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