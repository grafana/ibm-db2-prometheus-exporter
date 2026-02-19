local g = import './g.libsonnet';

{
  new(this): {
    local panels = this.grafana.panels,

    // Overview row - contains up status and active connections
    overviewRow:
      g.panel.row.new('Overview')
      + g.panel.row.withPanels([
        panels.upStatus { gridPos: { h: 6, w: 6 } },
        panels.activeConnections { gridPos: { h: 6, w: 18 } },
      ]),

    // Operations row - contains row operations and bufferpool hit ratio
    operationsRow:
      g.panel.row.new('Operations')
      + g.panel.row.withPanels([
        panels.rowOperations { gridPos: { h: 6, w: 12 } },
        panels.bufferpoolHitRatio { gridPos: { h: 6, w: 12 } },
      ]),

    // Tablespace row
    tablespaceRow:
      g.panel.row.new('Tablespace')
      + g.panel.row.withPanels([
        panels.tablespaceUsage { gridPos: { h: 6, w: 24 } },
      ]),

    // Locks row - contains average lock wait time, deadlocks, and locks
    locksRow:
      g.panel.row.new('Locks')
      + g.panel.row.withPanels([
        panels.averageLockWaitTime { gridPos: { h: 6, w: 8 } },
        panels.deadlocks { gridPos: { h: 6, w: 8 } },
        panels.locks { gridPos: { h: 6, w: 8 } },
      ]),

    // Logs row - contains log storage usage and log operations
    logsRow:
      g.panel.row.new('Logs')
      + g.panel.row.withPanels([
        panels.logStorageUsage { gridPos: { h: 6, w: 6 } },
        panels.logOperations { gridPos: { h: 6, w: 18 } },
      ]),
  },
}
