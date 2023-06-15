{
  _config+:: {
    dashboardTags: ['ibm-db2-mixin'],
    dashboardPeriod: 'now-3h',
    dashboardTimezone: 'default',
    dashboardRefresh: '1m',

    // alerts thresholds
    alertsHighLockWaitTime: 2000,
    alertsHighNumberOfDeadlocks: 5,
    alertsLogUsageReachingLimit: 90,

    enableLokiLogs: true,
  },
}
