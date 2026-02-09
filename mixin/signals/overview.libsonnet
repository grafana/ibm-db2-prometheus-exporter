function(this) {
  filteringSelector: this.filteringSelector,
  groupLabels: this.groupLabels,
  instanceLabels: this.instanceLabels,
  enableLokiLogs: this.enableLokiLogs,
  aggLevel: 'none',
  aggFunction: 'avg',
  alertsInterval: '5m',
  discoveryMetric: {
    prometheus: 'ibm_db2_application_active',
  },
  signals: {
    // Up status signal
    upStatus: {
      name: 'Up status',
      type: 'gauge',
      description: 'Whether the IBM DB2 exporter is up.',
      unit: 'short',
      sources: {
        prometheus: {
          expr: 'ibm_db2_up{%(queriesSelector)s}',
          legendCustomTemplate: '{{instance}}',
        },
      },
    },

    // Active connections signal
    activeConnections: {
      name: 'Active connections',
      type: 'gauge',
      description: 'The amount of active connections to the database.',
      unit: 'short',
      sources: {
        prometheus: {
          expr: 'ibm_db2_application_active{%(queriesSelector)s}',
          legendCustomTemplate: '{{database_name}}',
        },
      },
    },

    // Row operations signal (counter with increase)
    rowOperations: {
      name: 'Row operations',
      type: 'counter',
      description: 'The number of row operations that are being performed on the database.',
      unit: 'short',
      sources: {
        prometheus: {
          expr: 'ibm_db2_row_total{%(queriesSelector)s}',
          legendCustomTemplate: '{{database_name}} - {{row_state}}',
          rangeFunction: 'increase',
        },
      },
    },

    // Bufferpool hit ratio signal
    bufferpoolHitRatio: {
      name: 'Bufferpool hit ratio',
      type: 'gauge',
      description: 'The percentage of time that the database manager did not need to load a page from disk to service a page request.',
      unit: 'percent',
      sources: {
        prometheus: {
          expr: 'ibm_db2_bufferpool_hit_ratio{%(queriesSelector)s}',
          legendCustomTemplate: '{{database_name}} - {{bufferpool_name}}',
        },
      },
    },

    // Tablespace usage signal
    tablespaceUsage: {
      name: 'Tablespace usage',
      type: 'gauge',
      description: 'The size and usage of table spaces.',
      unit: 'decbytes',
      sources: {
        prometheus: {
          expr: 'ibm_db2_tablespace_usage{%(queriesSelector)s, tablespace_type="used"}',
          legendCustomTemplate: '{{database_name}} - {{tablespace_name}}',
        },
      },
    },

    // Average lock wait time signal
    averageLockWaitTime: {
      name: 'Average lock wait time',
      type: 'gauge',
      description: 'The average wait time for a database while acquiring locks.',
      unit: 'ms',
      sources: {
        prometheus: {
          expr: 'ibm_db2_lock_wait_time{%(queriesSelector)s}',
          legendCustomTemplate: '{{database_name}}',
        },
      },
    },

    // Deadlocks signal (counter with increase)
    deadlocks: {
      name: 'Deadlocks',
      type: 'counter',
      description: 'The number of deadlocks occurring on the database.',
      unit: 'short',
      sources: {
        prometheus: {
          expr: 'ibm_db2_deadlock_total{%(queriesSelector)s}',
          legendCustomTemplate: '{{database_name}}',
          rangeFunction: 'increase',
        },
      },
    },

    // Lock usage signal
    lockUsage: {
      name: 'Lock usage',
      type: 'gauge',
      description: 'The number of locks active and waiting in use in the database.',
      unit: 'short',
      sources: {
        prometheus: {
          expr: 'ibm_db2_lock_usage{%(queriesSelector)s}',
          legendCustomTemplate: '{{database_name}} - {{lock_state}}',
        },
      },
    },

    // Log storage usage - raw signal with complex expression
    logStorageUsage: {
      name: 'Log storage usage',
      type: 'raw',
      description: 'The percentage of allocated storage being used by the IBM DB2 instance.',
      unit: 'percent',
      sources: {
        prometheus: {
          expr: '100 * sum(ibm_db2_log_usage{%(queriesSelector)s, log_usage_type="used"}) by (instance, job, database_name) / clamp_min(sum(ibm_db2_log_usage{%(queriesSelector)s, log_usage_type="available"}) by (instance, job, database_name), 1)',
          legendCustomTemplate: '{{instance}}',
        },
      },
    },

    // Log operations signal (counter with increase)
    logOperations: {
      name: 'Log operations',
      type: 'counter',
      description: 'The number of log pages read and written to by the logger.',
      unit: 'short',
      sources: {
        prometheus: {
          expr: 'ibm_db2_log_operations_total{%(queriesSelector)s}',
          legendCustomTemplate: '{{database_name}} - {{log_member}} - {{log_operation_type}}',
          rangeFunction: 'increase',
        },
      },
    },
  },
}
