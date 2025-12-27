local g = import './g.libsonnet';

{
  local link = g.dashboard.link,
  new(this):
    {
      ibmDb2Overview:
        link.link.new('IBM DB2 overview', '/d/' + this.grafana.dashboards['ibm-db2-overview.json'].uid)
        + link.link.options.withKeepTime(true),
    } + if this.config.enableLokiLogs then
      {
        logs:
          link.link.new('IBM DB2 logs', '/d/' + this.grafana.dashboards['ibm-db2-logs.json'].uid)
          + link.link.options.withKeepTime(true),
      }
    else {},
}
