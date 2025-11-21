{
  local this = self,
  filteringSelector: 'job="integrations/ibm-db2"',
  groupLabels: ['job', 'cluster'],
  logLabels: ['job', 'cluster', 'instance'],
  instanceLabels: ['instance', 'database_name'],

  uid: 'ibm-db2',
  dashboardTags: [self.uid],
  dashboardNamePrefix: 'IBM DB2',
  dashboardPeriod: 'now-1h',
  dashboardTimezone: 'default',
  dashboardRefresh: '1m',
  metricsSource: ['prometheus'],  // metrics source for signals


  // Logging configuration
  enableLokiLogs: true,
  extraLogLabels: ['level', 'severity'],  // Required by logs-lib
  logsVolumeGroupBy: 'level',
  showLogsVolume: true,

  // alert thresholds
  alertsHighLockWaitTime: 2000,  // ms
  alertsHighNumberOfDeadlocks: 5,  // count
  alertsLogUsageReachingLimit: 90,  // %

  signals+: {
    overview: (import './signals/overview.libsonnet')(this),
  },
}
