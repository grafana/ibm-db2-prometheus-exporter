local g = import './g.libsonnet';

{
  new(this):
    local t = this;
    local vars = t.grafana.variables;
    local rows = t.grafana.rows;

    {
      'ibm-db2-overview.json':
        g.dashboard.new('IBM DB2 overview')
        + g.dashboard.withUid('ibm-db2-overview')
        + g.dashboard.withTags(t.config.dashboardTags)
        + g.dashboard.withTimezone(t.config.dashboardTimezone)
        + g.dashboard.withRefresh(t.config.dashboardRefresh)
        + g.dashboard.time.withFrom(t.config.dashboardPeriod)
        + g.dashboard.withVariables(
          std.flattenArrays([
            [vars.datasources.prometheus],
            if t.config.enableLokiLogs then [vars.datasources.loki] else [],
            vars.multiInstance,
            [
              g.dashboard.variable.query.new('database_name')
              + g.dashboard.variable.query.withDatasourceFromVariable(vars.datasources.prometheus)
              + g.dashboard.variable.query.queryTypes.withLabelValues('database_name', 'ibm_db2_application_active{job=~"$job", instance=~"$instance"}')
              + g.dashboard.variable.query.generalOptions.withLabel('Database')
              + g.dashboard.variable.query.selectionOptions.withMulti(true)
              + g.dashboard.variable.query.selectionOptions.withIncludeAll(true, '')
              + g.dashboard.variable.query.refresh.onLoad()
              + g.dashboard.variable.query.refresh.onTime(),
            ],
          ])
        )
        + g.dashboard.withPanels(
          g.util.panel.resolveCollapsedFlagOnRows(
            g.util.grid.wrapPanels(
              [
                rows.overviewRow,
                rows.operationsRow,
                rows.tablespaceRow,
                rows.locksRow,
                rows.logsRow,
              ]
            )
          )
        ),
    },
}
