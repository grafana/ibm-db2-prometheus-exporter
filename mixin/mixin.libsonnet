local ibmdb2lib = import './main.libsonnet';

local ibmdb2 = ibmdb2lib.new();

{
  grafanaDashboards+:: ibmdb2.grafana.dashboards,
  prometheusAlerts+:: ibmdb2.prometheus.alerts,
  prometheusRules+:: ibmdb2.prometheus.recordingRules,
}
