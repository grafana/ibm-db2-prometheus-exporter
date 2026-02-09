local g = import './g.libsonnet';
local commonlib = import 'common-lib/common/main.libsonnet';

{
  new(this): {
    local t = this,
    local signals = t.signals.overview,

    // Up status (stat panel with mappings)
    upStatus:
      commonlib.panels.generic.stat.base.new(
        'Up status',
        targets=[signals.upStatus.asTarget() { intervalFactor: 2 }],
        description='Whether the agent integration is up for this database.'
      )
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

    // Active connections (timeseries)
    activeConnections:
      commonlib.panels.generic.timeSeries.base.new(
        'Active connections',
        targets=[signals.activeConnections.asTarget() { intervalFactor: 2 }],
        description='The amount of active connections to the database.'
      )
      + g.panel.timeSeries.standardOptions.withUnit('short')
      + g.panel.timeSeries.options.legend.withDisplayMode('table'),

    // Row operations (timeseries with increase)
    rowOperations:
      commonlib.panels.generic.timeSeries.base.new(
        'Row operations',
        targets=[signals.rowOperations.asTarget() { interval: '1m', intervalFactor: 2 }],
        description='The number of row operations that are being performed on the database.'
      )
      + g.panel.timeSeries.standardOptions.withUnit('short')
      + g.panel.timeSeries.options.legend.withDisplayMode('table'),

    // Bufferpool hit ratio (timeseries)
    bufferpoolHitRatio:
      commonlib.panels.generic.timeSeries.base.new(
        'Bufferpool hit ratio',
        targets=[signals.bufferpoolHitRatio.asTarget() { intervalFactor: 2 }],
        description='The percentage of time that the database manager did not need to load a page from disk to service a page request.'
      )
      + g.panel.timeSeries.standardOptions.withUnit('percent'),

    // Tablespace usage (timeseries)
    tablespaceUsage:
      commonlib.panels.generic.timeSeries.base.new(
        'Tablespace usage',
        targets=[signals.tablespaceUsage.asTarget() { intervalFactor: 2 }],
        description='The size and usage of table spaces.'
      )
      + g.panel.timeSeries.standardOptions.withUnit('decbytes'),

    // Average lock wait time (timeseries with thresholds)
    averageLockWaitTime:
      commonlib.panels.generic.timeSeries.base.new(
        'Average lock wait time',
        targets=[signals.averageLockWaitTime.asTarget() { intervalFactor: 2 }],
        description='The average wait time for a database while acquiring locks.'
      )
      + g.panel.timeSeries.standardOptions.withUnit('ms')
      + g.panel.timeSeries.standardOptions.thresholds.withSteps([
        g.panel.timeSeries.thresholdStep.withColor('green')
        + g.panel.timeSeries.thresholdStep.withValue(null),
        g.panel.timeSeries.thresholdStep.withColor('red')
        + g.panel.timeSeries.thresholdStep.withValue(t.config.alertsHighLockWaitTime),
      ]),

    // Deadlocks (timeseries with increase)
    deadlocks:
      commonlib.panels.generic.timeSeries.base.new(
        'Deadlocks',
        targets=[signals.deadlocks.asTarget() { interval: '1m', intervalFactor: 2 }],
        description='The number of deadlocks occurring on the database.'
      )
      + g.panel.timeSeries.standardOptions.withUnit('short')
      + g.panel.timeSeries.standardOptions.thresholds.withSteps([
        g.panel.timeSeries.thresholdStep.withColor('green')
        + g.panel.timeSeries.thresholdStep.withValue(null),
        g.panel.timeSeries.thresholdStep.withColor('red')
        + g.panel.timeSeries.thresholdStep.withValue(t.config.alertsHighNumberOfDeadlocks),
      ]),

    // Locks (timeseries)
    locks:
      commonlib.panels.generic.timeSeries.base.new(
        'Locks',
        targets=[signals.lockUsage.asTarget() { intervalFactor: 2 }],
        description='The number of locks active and waiting in use in the database.'
      )
      + g.panel.timeSeries.standardOptions.withUnit('short'),

    // Log storage usage (stat panel)
    logStorageUsage:
      commonlib.panels.generic.stat.base.new(
        'Log storage usage',
        targets=[signals.logStorageUsage.asTarget() { intervalFactor: 2 }],
        description='The percentage of allocated storage being used by the IBM DB2 instance.'
      )
      + g.panel.stat.standardOptions.withUnit('percent')
      + g.panel.stat.standardOptions.color.withMode('thresholds')
      + g.panel.stat.options.withColorMode('value')
      + g.panel.stat.options.withGraphMode('none')
      + g.panel.stat.options.reduceOptions.withCalcs(['lastNotNull']),

    // Log operations (timeseries with increase)
    logOperations:
      commonlib.panels.generic.timeSeries.base.new(
        'Log operations',
        targets=[signals.logOperations.asTarget() { interval: '1m', intervalFactor: 2 }],
        description='The number of log pages read and written to by the logger.'
      )
      + g.panel.timeSeries.standardOptions.withUnit('short'),
  },
}
