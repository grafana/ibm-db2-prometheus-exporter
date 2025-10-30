local g = import './g.libsonnet';
local commonlib = import 'common-lib/common/main.libsonnet';

{
  new(this): {
    local t = this,
    local signals = t.signals.overview,

    // Panel 1: Up status (stat panel with mappings)
    upStatus:
      g.panel.stat.new('Up status')
      + g.panel.stat.panelOptions.withDescription('Whether the agent integration is up for this database.')
      + g.panel.stat.queryOptions.withTargets([
        signals.upStatus.asTarget(),
      ])
      + g.panel.stat.standardOptions.color.withMode('thresholds')
      + g.panel.stat.standardOptions.withMappings([
        g.panel.stat.standardOptions.mapping.ValueMap.withType()
        + g.panel.stat.standardOptions.mapping.ValueMap.withOptions({
          '0': { color: 'red', index: 0, text: 'Not OK' },
          '1': { color: 'green', index: 1, text: 'OK' },
        }),
      ])
      + g.panel.stat.options.withColorMode('value')
      + g.panel.stat.options.withGraphMode('none')
      + g.panel.stat.options.reduceOptions.withCalcs(['lastNotNull']),

    // Panel 2: Active connections (timeseries)
    activeConnections:
      g.panel.timeSeries.new('Active connections')
      + g.panel.timeSeries.panelOptions.withDescription('The amount of active connections to the database.')
      + g.panel.timeSeries.queryOptions.withTargets([
        signals.activeConnections.asTarget(),
      ])
      + g.panel.timeSeries.standardOptions.withUnit('none')
      + g.panel.timeSeries.options.tooltip.withMode('multi')
      + g.panel.timeSeries.options.tooltip.withSort('desc'),

    // Panel 3: Row operations (timeseries with increase)
    rowOperations:
      g.panel.timeSeries.new('Row operations')
      + g.panel.timeSeries.panelOptions.withDescription('The number of row operations that are being performed on the database.')
      + g.panel.timeSeries.queryOptions.withTargets([
        signals.rowOperations.asTarget()
        + g.query.prometheus.withInterval('1m'),
      ])
      + g.panel.timeSeries.standardOptions.withUnit('none')
      + g.panel.timeSeries.options.tooltip.withMode('multi')
      + g.panel.timeSeries.options.tooltip.withSort('desc'),

    // Panel 4: Bufferpool hit ratio (timeseries)
    bufferpoolHitRatio:
      g.panel.timeSeries.new('Bufferpool hit ratio')
      + g.panel.timeSeries.panelOptions.withDescription('The percentage of time that the database manager did not need to load a page from disk to service a page request.')
      + g.panel.timeSeries.queryOptions.withTargets([
        signals.bufferpoolHitRatio.asTarget(),
      ])
      + g.panel.timeSeries.standardOptions.withUnit('percent')
      + g.panel.timeSeries.options.tooltip.withMode('multi')
      + g.panel.timeSeries.options.tooltip.withSort('desc'),

    // Panel 5: Tablespace usage (timeseries with thresholds)
    tablespaceUsage:
      g.panel.timeSeries.new('Tablespace usage')
      + g.panel.timeSeries.panelOptions.withDescription('The size and usage of table spaces.')
      + g.panel.timeSeries.queryOptions.withTargets([
        signals.tablespaceUsage.asTarget(),
      ])
      + g.panel.timeSeries.standardOptions.withUnit('decbytes')
      + g.panel.timeSeries.standardOptions.thresholds.withSteps([
        g.panel.timeSeries.thresholdStep.withColor('green')
        + g.panel.timeSeries.thresholdStep.withValue(null),
        g.panel.timeSeries.thresholdStep.withColor('red')
        + g.panel.timeSeries.thresholdStep.withValue(80),
      ])
      + g.panel.timeSeries.options.tooltip.withMode('multi')
      + g.panel.timeSeries.options.tooltip.withSort('desc'),

    // Panel 6: Average lock wait time (timeseries with thresholds)
    averageLockWaitTime:
      g.panel.timeSeries.new('Average lock wait time')
      + g.panel.timeSeries.panelOptions.withDescription('The average wait time for a database while acquiring locks.')
      + g.panel.timeSeries.queryOptions.withTargets([
        signals.averageLockWaitTime.asTarget(),
      ])
      + g.panel.timeSeries.standardOptions.withUnit('ms')
      + g.panel.timeSeries.standardOptions.thresholds.withSteps([
        g.panel.timeSeries.thresholdStep.withColor('green')
        + g.panel.timeSeries.thresholdStep.withValue(null),
        g.panel.timeSeries.thresholdStep.withColor('red')
        + g.panel.timeSeries.thresholdStep.withValue(80),
      ])
      + g.panel.timeSeries.options.tooltip.withMode('multi')
      + g.panel.timeSeries.options.tooltip.withSort('desc'),

    // Panel 7: Deadlocks (timeseries with increase)
    deadlocks:
      g.panel.timeSeries.new('Deadlocks')
      + g.panel.timeSeries.panelOptions.withDescription('The number of deadlocks occurring on the database.')
      + g.panel.timeSeries.queryOptions.withTargets([
        signals.deadlocks.asTarget()
        + g.query.prometheus.withInterval('1m'),
      ])
      + g.panel.timeSeries.standardOptions.withUnit('none')
      + g.panel.timeSeries.standardOptions.thresholds.withSteps([
        g.panel.timeSeries.thresholdStep.withColor('green')
        + g.panel.timeSeries.thresholdStep.withValue(null),
        g.panel.timeSeries.thresholdStep.withColor('red')
        + g.panel.timeSeries.thresholdStep.withValue(80),
      ])
      + g.panel.timeSeries.options.tooltip.withMode('multi')
      + g.panel.timeSeries.options.tooltip.withSort('desc'),

    // Panel 8: Locks (timeseries with custom override)
    locks:
      g.panel.timeSeries.new('Locks')
      + g.panel.timeSeries.panelOptions.withDescription('The number of locks active and waiting in use in the database.')
      + g.panel.timeSeries.queryOptions.withTargets([
        signals.lockUsage.asTarget(),
      ])
      + g.panel.timeSeries.standardOptions.withUnit('none')
      + g.panel.timeSeries.standardOptions.withOverrides([
        g.panel.timeSeries.fieldOverride.byRegexp.new('/./')
        + g.panel.timeSeries.fieldOverride.byRegexp.withProperty('custom.axisSoftMax', -4),
      ])
      + g.panel.timeSeries.options.tooltip.withMode('multi')
      + g.panel.timeSeries.options.tooltip.withSort('desc'),

    // Panel 9: Diagnostic logs (logs panel - Loki)
    diagnosticLogs:
      g.panel.logs.new('Diagnostic logs')
      + g.panel.logs.panelOptions.withDescription('Recent logs from diagnostic log file.')
      + g.panel.logs.queryOptions.withTargets([
        g.query.loki.new(
          '${loki_datasource}',
          '{' + t.config.filteringSelector + '} |= `` | (filename=~"/home/.*/sqllib/db2dump/DIAG.*/db2diag.log|/home/.*/sqllib/db2dump/db2diag.log" or log_type="db2diag")'
        ),
      ])
      + g.panel.logs.options.withEnableLogDetails(true)
      + g.panel.logs.options.withShowCommonLabels(false)
      + g.panel.logs.options.withShowTime(false)
      + g.panel.logs.options.withWrapLogMessage(false),

    // Panel 10: Log storage usage (stat panel)
    logStorageUsage:
      g.panel.stat.new('Log storage usage')
      + g.panel.stat.panelOptions.withDescription('The percentage of allocated storage being used by the IBM DB2 instance.')
      + g.panel.stat.queryOptions.withTargets([
        signals.logStorageUsage.asTarget(),
      ])
      + g.panel.stat.standardOptions.withUnit('percent')
      + g.panel.stat.standardOptions.color.withMode('thresholds')
      + g.panel.stat.options.withColorMode('value')
      + g.panel.stat.options.withGraphMode('none')
      + g.panel.stat.options.reduceOptions.withCalcs(['lastNotNull']),

    // Panel 11: Log operations (timeseries with increase)
    logOperations:
      g.panel.timeSeries.new('Log operations')
      + g.panel.timeSeries.panelOptions.withDescription('The number of log pages read and written to by the logger.')
      + g.panel.timeSeries.queryOptions.withTargets([
        signals.logOperations.asTarget()
        + g.query.prometheus.withInterval('1m'),
      ])
      + g.panel.timeSeries.standardOptions.withUnit('none')
      + g.panel.timeSeries.options.tooltip.withMode('multi')
      + g.panel.timeSeries.options.tooltip.withSort('desc'),
  },
}
