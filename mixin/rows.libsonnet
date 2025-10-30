local g = import './g.libsonnet';

{
  new(this): {
    local panels = this.grafana.panels,

    // Overview row - contains up status and active connections
    overviewRow:
      g.panel.row.new('Overview')
      + g.panel.row.withPanels([
        panels.upStatus { gridPos: { h: 6, w: 6, x: 0, y: 0 } },
        panels.activeConnections { gridPos: { h: 6, w: 18, x: 6, y: 0 } },
      ]),

    // Operations row - contains row operations and bufferpool hit ratio
    operationsRow:
      g.panel.row.new('Operations')
      + g.panel.row.withPanels([
        panels.rowOperations { gridPos: { h: 6, w: 12, x: 0, y: 1 } },
        panels.bufferpoolHitRatio { gridPos: { h: 6, w: 12, x: 12, y: 1 } },
      ]),

    // Tablespace row
    tablespaceRow:
      g.panel.row.new('Tablespace')
      + g.panel.row.withPanels([
        panels.tablespaceUsage { gridPos: { h: 6, w: 24, x: 0, y: 2 } },
      ]),

    // Locks row - contains average lock wait time, deadlocks, and locks
    locksRow:
      g.panel.row.new('Locks')
      + g.panel.row.withPanels([
        panels.averageLockWaitTime { gridPos: { h: 6, w: 8, x: 0, y: 3 } },
        panels.deadlocks { gridPos: { h: 6, w: 8, x: 8, y: 3 } },
        panels.locks { gridPos: { h: 6, w: 8, x: 16, y: 3 } },
      ]),

    // Logs row - contains diagnostic logs (if Loki is enabled), log storage usage, and log operations
    logsRow:
      g.panel.row.new('Logs')
      + g.panel.row.withPanels(
        (
          if this.config.enableLokiLogs then [
            panels.diagnosticLogs { gridPos: { h: 6, w: 24, x: 0, y: 5 } },
            panels.logStorageUsage { gridPos: { h: 6, w: 6, x: 0, y: 6 } },
            panels.logOperations { gridPos: { h: 6, w: 18, x: 6, y: 6 } },
          ] else [
            panels.logStorageUsage { gridPos: { h: 6, w: 6, x: 0, y: 5 } },
            panels.logOperations { gridPos: { h: 6, w: 18, x: 6, y: 5 } },
          ]
        )
      ),
  },
}
