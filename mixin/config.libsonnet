{
  _config+:: {
    dashboardTags: ['ibm-db2-mixin'],
    dashboardPeriod: 'now-3h',
    dashboardTimezone: 'default',
    dashboardRefresh: '1m',

    // alerts thresholds
    alertsHighLockWaitTime: 2000, //ms
    alertsHighNumberOfDeadlocks: 5, //count
    alertsLogUsageReachingLimit: 90, //percent 0-100

    enableLokiLogs: true,
  },
}
