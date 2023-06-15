local g = (import 'grafana-builder/grafana.libsonnet');
local grafana = (import 'grafonnet/grafana.libsonnet');
local dashboard = grafana.dashboard;
local template = grafana.template;
local prometheus = grafana.prometheus;

local dashboardUid = 'ibm-db2-overview';

local promDatasourceName = 'prometheus_datasource';
local lokiDatasourceName = 'loki_datasource';

local promDatasource = {
  uid: '${%s}' % promDatasourceName,
};

local lokiDatasource = {
  uid: '${%s}' % lokiDatasourceName,
};

local upStatusPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'ibm_db2_up{job=~"$job",instance=~"$instance", database_name=~"$database_name"}',
      datasource=promDatasource,
      legendFormat='{{instance}}',
    ),
  ],
  type: 'stat',
  title: 'Up status',
  description: 'Whether the agent integration is up for this database.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'thresholds',
      },
      mappings: [
        {
          options: {
            '0': {
              color: 'red',
              index: 0,
              text: 'Not OK',
            },
            '1': {
              color: 'green',
              index: 1,
              text: 'OK',
            },
          },
          type: 'value',
        },
      ],
      thresholds: {
        mode: 'absolute',
        steps: [
          {
            color: 'green',
            value: null,
          },
        ],
      },
    },
    overrides: [],
  },
  options: {
    colorMode: 'value',
    graphMode: 'none',
    justifyMode: 'auto',
    orientation: 'auto',
    reduceOptions: {
      calcs: [
        'lastNotNull',
      ],
      fields: '',
      values: false,
    },
    textMode: 'auto',
  },
  pluginVersion: '10.0.1-cloud.2.a7a20fbf',
};

local activeConnectionsPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'ibm_db2_application_active{job=~"$job",instance=~"$instance", database_name=~"$database_name"}',
      datasource=promDatasource,
      legendFormat='{{database_name}}',
    ),
  ],
  type: 'timeseries',
  title: 'Active connections',
  description: 'The amount of active connections to the database.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'palette-classic',
      },
      custom: {
        axisCenteredZero: false,
        axisColorMode: 'text',
        axisLabel: '',
        axisPlacement: 'auto',
        barAlignment: 0,
        drawStyle: 'line',
        fillOpacity: 0,
        gradientMode: 'none',
        hideFrom: {
          legend: false,
          tooltip: false,
          viz: false,
        },
        lineInterpolation: 'linear',
        lineWidth: 1,
        pointSize: 5,
        scaleDistribution: {
          type: 'linear',
        },
        showPoints: 'auto',
        spanNulls: false,
        stacking: {
          group: 'A',
          mode: 'none',
        },
        thresholdsStyle: {
          mode: 'off',
        },
      },
      mappings: [],
      thresholds: {
        mode: 'absolute',
        steps: [
          {
            color: 'green',
            value: null,
          },
        ],
      },
      unit: 'none',
    },
    overrides: [],
  },
  options: {
    legend: {
      calcs: [],
      displayMode: 'list',
      placement: 'bottom',
      showLegend: true,
    },
    tooltip: {
      mode: 'multi',
      sort: 'desc',
    },
  },
};

local rowOperationsPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'increase(ibm_db2_row_total{job=~"$job",instance=~"$instance",database_name=~"$database_name"}[$__interval:])',
      datasource=promDatasource,
      legendFormat='{{database_name}} - {{row_state}}',
      interval='1m',
    ),
  ],
  type: 'timeseries',
  title: 'Row operations',
  description: 'The number of row operations that are being performed on the database.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'palette-classic',
      },
      custom: {
        axisCenteredZero: false,
        axisColorMode: 'text',
        axisLabel: '',
        axisPlacement: 'auto',
        barAlignment: 0,
        drawStyle: 'line',
        fillOpacity: 0,
        gradientMode: 'none',
        hideFrom: {
          legend: false,
          tooltip: false,
          viz: false,
        },
        lineInterpolation: 'linear',
        lineWidth: 1,
        pointSize: 5,
        scaleDistribution: {
          type: 'linear',
        },
        showPoints: 'auto',
        spanNulls: false,
        stacking: {
          group: 'A',
          mode: 'none',
        },
        thresholdsStyle: {
          mode: 'off',
        },
      },
      mappings: [],
      thresholds: {
        mode: 'absolute',
        steps: [
          {
            color: 'green',
            value: null,
          },
        ],
      },
      unit: 'none',
    },
    overrides: [],
  },
  options: {
    legend: {
      calcs: [],
      displayMode: 'list',
      placement: 'bottom',
      showLegend: true,
    },
    tooltip: {
      mode: 'multi',
      sort: 'desc',
    },
  },
};

local bufferpoolHitRatioPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'ibm_db2_bufferpool_hit_ratio{job=~"$job",instance=~"$instance", database_name=~"$database_name"}',
      datasource=promDatasource,
      legendFormat='{{database_name}} - {{bufferpool_name}}',
    ),
  ],
  type: 'timeseries',
  title: 'Bufferpool hit ratio',
  description: 'The percentage of time that the database manager did not need to load a page from disk to service a page request.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'palette-classic',
      },
      custom: {
        axisCenteredZero: false,
        axisColorMode: 'text',
        axisLabel: '',
        axisPlacement: 'auto',
        barAlignment: 0,
        drawStyle: 'line',
        fillOpacity: 0,
        gradientMode: 'none',
        hideFrom: {
          legend: false,
          tooltip: false,
          viz: false,
        },
        lineInterpolation: 'linear',
        lineWidth: 1,
        pointSize: 5,
        scaleDistribution: {
          type: 'linear',
        },
        showPoints: 'auto',
        spanNulls: false,
        stacking: {
          group: 'A',
          mode: 'none',
        },
        thresholdsStyle: {
          mode: 'off',
        },
      },
      mappings: [],
      thresholds: {
        mode: 'absolute',
        steps: [
          {
            color: 'green',
            value: null,
          },
        ],
      },
      unit: 'percent',
    },
    overrides: [],
  },
  options: {
    legend: {
      calcs: [],
      displayMode: 'list',
      placement: 'bottom',
      showLegend: true,
    },
    tooltip: {
      mode: 'multi',
      sort: 'desc',
    },
  },
};

local tablespaceUsagePanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'ibm_db2_tablespace_usage{job=~"$job",instance=~"$instance",database_name=~"$database_name",tablespace_type="used"}',
      datasource=promDatasource,
      legendFormat='{{database_name}} - {{tablespace_name}}',
    ),
  ],
  type: 'timeseries',
  title: 'Tablespace usage',
  description: 'The size and usage of table spaces.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'palette-classic',
      },
      custom: {
        axisCenteredZero: false,
        axisColorMode: 'text',
        axisLabel: '',
        axisPlacement: 'auto',
        barAlignment: 0,
        drawStyle: 'line',
        fillOpacity: 0,
        gradientMode: 'none',
        hideFrom: {
          legend: false,
          tooltip: false,
          viz: false,
        },
        lineInterpolation: 'linear',
        lineWidth: 1,
        pointSize: 5,
        scaleDistribution: {
          type: 'linear',
        },
        showPoints: 'auto',
        spanNulls: false,
        stacking: {
          group: 'A',
          mode: 'none',
        },
        thresholdsStyle: {
          mode: 'off',
        },
      },
      mappings: [],
      thresholds: {
        mode: 'absolute',
        steps: [
          {
            color: 'green',
            value: null,
          },
          {
            color: 'red',
            value: 80,
          },
        ],
      },
      unit: 'decbytes',
    },
    overrides: [],
  },
  options: {
    legend: {
      calcs: [],
      displayMode: 'list',
      placement: 'bottom',
      showLegend: true,
    },
    tooltip: {
      mode: 'multi',
      sort: 'desc',
    },
  },
};

local averageLockWaitTimePanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'ibm_db2_lock_wait_time{job=~"$job",instance=~"$instance", database_name=~"$database_name"}',
      datasource=promDatasource,
      legendFormat='{{database_name}}',
    ),
  ],
  type: 'timeseries',
  title: 'Average lock wait time',
  description: 'The average wait time for a database while acquiring locks.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'palette-classic',
      },
      custom: {
        axisCenteredZero: false,
        axisColorMode: 'text',
        axisLabel: '',
        axisPlacement: 'auto',
        barAlignment: 0,
        drawStyle: 'line',
        fillOpacity: 0,
        gradientMode: 'none',
        hideFrom: {
          legend: false,
          tooltip: false,
          viz: false,
        },
        lineInterpolation: 'linear',
        lineWidth: 1,
        pointSize: 5,
        scaleDistribution: {
          type: 'linear',
        },
        showPoints: 'auto',
        spanNulls: false,
        stacking: {
          group: 'A',
          mode: 'none',
        },
        thresholdsStyle: {
          mode: 'off',
        },
      },
      mappings: [],
      thresholds: {
        mode: 'absolute',
        steps: [
          {
            color: 'green',
            value: null,
          },
          {
            color: 'red',
            value: 80,
          },
        ],
      },
      unit: 'ms',
    },
    overrides: [],
  },
  options: {
    legend: {
      calcs: [],
      displayMode: 'list',
      placement: 'bottom',
      showLegend: true,
    },
    tooltip: {
      mode: 'multi',
      sort: 'desc',
    },
  },
};

local deadlocksPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'increase(ibm_db2_deadlock_total{job=~"$job",instance=~"$instance", database_name=~"$database_name"}[$__interval:])',
      datasource=promDatasource,
      legendFormat='{{database_name}}',
      interval='1m',
    ),
  ],
  type: 'timeseries',
  title: 'Deadlocks',
  description: 'The number of deadlocks occurring on the database.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'palette-classic',
      },
      custom: {
        axisCenteredZero: false,
        axisColorMode: 'text',
        axisLabel: '',
        axisPlacement: 'auto',
        barAlignment: 0,
        drawStyle: 'line',
        fillOpacity: 0,
        gradientMode: 'none',
        hideFrom: {
          legend: false,
          tooltip: false,
          viz: false,
        },
        lineInterpolation: 'linear',
        lineWidth: 1,
        pointSize: 5,
        scaleDistribution: {
          type: 'linear',
        },
        showPoints: 'auto',
        spanNulls: false,
        stacking: {
          group: 'A',
          mode: 'none',
        },
        thresholdsStyle: {
          mode: 'off',
        },
      },
      mappings: [],
      thresholds: {
        mode: 'absolute',
        steps: [
          {
            color: 'green',
            value: null,
          },
          {
            color: 'red',
            value: 80,
          },
        ],
      },
      unit: 'none',
    },
    overrides: [],
  },
  options: {
    legend: {
      calcs: [],
      displayMode: 'list',
      placement: 'bottom',
      showLegend: true,
    },
    tooltip: {
      mode: 'multi',
      sort: 'desc',
    },
  },
};

local locksPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'ibm_db2_lock_usage{job=~"$job",instance=~"$instance",database_name=~"$database_name"}',
      datasource=promDatasource,
      legendFormat='{{database_name}} - {{lock_state}}',
    ),
  ],
  type: 'timeseries',
  title: 'Locks',
  description: 'The number of locks active and waiting in use in the database.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'palette-classic',
      },
      custom: {
        axisCenteredZero: false,
        axisColorMode: 'text',
        axisLabel: '',
        axisPlacement: 'auto',
        axisSoftMax: -4,
        barAlignment: 0,
        drawStyle: 'line',
        fillOpacity: 0,
        gradientMode: 'none',
        hideFrom: {
          legend: false,
          tooltip: false,
          viz: false,
        },
        lineInterpolation: 'linear',
        lineWidth: 1,
        pointSize: 5,
        scaleDistribution: {
          type: 'linear',
        },
        showPoints: 'auto',
        spanNulls: false,
        stacking: {
          group: 'A',
          mode: 'none',
        },
        thresholdsStyle: {
          mode: 'off',
        },
      },
      mappings: [],
      thresholds: {
        mode: 'absolute',
        steps: [
          {
            color: 'green',
            value: null,
          },
        ],
      },
      unit: 'none',
    },
    overrides: [],
  },
  options: {
    legend: {
      calcs: [],
      displayMode: 'list',
      placement: 'bottom',
      showLegend: true,
    },
    tooltip: {
      mode: 'multi',
      sort: 'desc',
    },
  },
};

local logsRow = {
  datasource: promDatasource,
  targets: [],
  type: 'row',
  title: 'Logs',
  collapsed: false,
};

local diagnosticLogsPanel = {
  datasource: lokiDatasource,
  targets: [
    {
      datasource: lokiDatasource,
      editorMode: 'code',
      expr: '{filename=~"/home/.*/sqllib/db2dump/DIAG.*/db2diag.log|/home/.*/sqllib/db2dump/db2diag.log"} |= ``',
      queryType: 'range',
      refId: 'A',
    },
  ],
  type: 'logs',
  title: 'Diagnostic logs',
  description: 'Recent logs from diagnostic log file.',
  options: {
    dedupStrategy: 'none',
    enableLogDetails: true,
    prettifyLogMessage: false,
    showCommonLabels: false,
    showLabels: false,
    showTime: false,
    sortOrder: 'Descending',
    wrapLogMessage: false,
  },
};

local logStorageUsagePanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      '100 * sum(ibm_db2_log_usage{job=~"$job",instance=~"$instance", database_name=~"$database_name", log_usage_type="used"}) by (instance, job, database_name) / sum(ibm_db2_log_usage{job=~"$job",instance=~"$instance", database_name=~"$database_name", log_usage_type="available"}) by (instance, job, database_name)',
      datasource=promDatasource,
      legendFormat='{{instance}}',
    ),
  ],
  type: 'stat',
  title: 'Log storage usage',
  description: 'The percentage of allocated storage being used by the IBM DB2 instance.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'thresholds',
      },
      mappings: [],
      thresholds: {
        mode: 'absolute',
        steps: [
          {
            color: 'green',
            value: null,
          },
        ],
      },
      unit: 'percent',
    },
    overrides: [],
  },
  options: {
    colorMode: 'value',
    graphMode: 'none',
    justifyMode: 'auto',
    orientation: 'auto',
    reduceOptions: {
      calcs: [
        'lastNotNull',
      ],
      fields: '',
      values: false,
    },
    textMode: 'auto',
  },
  pluginVersion: '10.0.1-cloud.2.a7a20fbf',
};

local logOperationsPanel = {
  datasource: promDatasource,
  targets: [
    prometheus.target(
      'increase(ibm_db2_log_operations_total{job=~"$job",instance=~"$instance",database_name=~"$database_name"}[$__interval:])',
      datasource=promDatasource,
      legendFormat='{{database_name}} - {{log_member}} - {{log_operation_type}}',
      interval='1m',
    ),
  ],
  type: 'timeseries',
  title: 'Log operations',
  description: 'The number of log pages read and written to by the logger.',
  fieldConfig: {
    defaults: {
      color: {
        mode: 'palette-classic',
      },
      custom: {
        axisCenteredZero: false,
        axisColorMode: 'text',
        axisLabel: '',
        axisPlacement: 'auto',
        barAlignment: 0,
        drawStyle: 'line',
        fillOpacity: 0,
        gradientMode: 'none',
        hideFrom: {
          legend: false,
          tooltip: false,
          viz: false,
        },
        lineInterpolation: 'linear',
        lineWidth: 1,
        pointSize: 5,
        scaleDistribution: {
          type: 'linear',
        },
        showPoints: 'auto',
        spanNulls: false,
        stacking: {
          group: 'A',
          mode: 'none',
        },
        thresholdsStyle: {
          mode: 'off',
        },
      },
      mappings: [],
      thresholds: {
        mode: 'absolute',
        steps: [
          {
            color: 'green',
            value: null,
          },
        ],
      },
      unit: 'none',
    },
    overrides: [],
  },
  options: {
    legend: {
      calcs: [],
      displayMode: 'list',
      placement: 'bottom',
      showLegend: true,
    },
    tooltip: {
      mode: 'multi',
      sort: 'desc',
    },
  },
};

{
  grafanaDashboards+:: {
    'ibm-db2-overview.json':
      dashboard.new(
        'IBM DB2 overview',
        time_from='%s' % $._config.dashboardPeriod,
        tags=($._config.dashboardTags),
        timezone='%s' % $._config.dashboardTimezone,
        refresh='%s' % $._config.dashboardRefresh,
        description='',
        uid=dashboardUid,
      )

      .addTemplates(
        std.flattenArrays([
          [
            template.datasource(
              promDatasourceName,
              'prometheus',
              null,
              label='Data Source',
              refresh='load'
            ),
          ],
          if $._config.enableLokiLogs then [
            template.datasource(
              lokiDatasourceName,
              'loki',
              null,
              label='Loki Datasource',
              refresh='load'
            ),
          ] else [],
          [
            template.new(
              'job',
              promDatasource,
              'label_values(ibm_db2_application_active,job)',
              label='Job',
              refresh=1,
              includeAll=false,
              multi=false,
              allValues='',
              sort=0
            ),
            template.new(
              'instance',
              promDatasource,
              'label_values(ibm_db2_application_active,instance)',
              label='Instance',
              refresh=1,
              includeAll=false,
              multi=false,
              allValues='',
              sort=0
            ),
            template.new(
              'database_name',
              promDatasource,
              'label_values(ibm_db2_application_active,database_name)',
              label='Database',
              refresh=1,
              includeAll=true,
              multi=true,
              allValues='',
              sort=0
            ),
          ],
        ])
      )
      .addPanels(
        std.flattenArrays([
          [
            upStatusPanel { gridPos: { h: 6, w: 6, x: 0, y: 0 } },
            activeConnectionsPanel { gridPos: { h: 6, w: 18, x: 6, y: 0 } },
            rowOperationsPanel { gridPos: { h: 6, w: 12, x: 0, y: 6 } },
            bufferpoolHitRatioPanel { gridPos: { h: 6, w: 12, x: 12, y: 6 } },
            tablespaceUsagePanel { gridPos: { h: 6, w: 24, x: 0, y: 12 } },
            averageLockWaitTimePanel { gridPos: { h: 6, w: 8, x: 0, y: 18 } },
            deadlocksPanel { gridPos: { h: 6, w: 8, x: 8, y: 18 } },
            locksPanel { gridPos: { h: 6, w: 8, x: 16, y: 18 } },
            logsRow { gridPos: { h: 1, w: 24, x: 0, y: 24 } },
          ],
          if $._config.enableLokiLogs then [
            diagnosticLogsPanel { gridPos: { h: 6, w: 24, x: 0, y: 25 } },
          ] else [],
          [
            logStorageUsagePanel { gridPos: { h: 6, w: 6, x: 0, y: 31 } },
            logOperationsPanel { gridPos: { h: 6, w: 18, x: 6, y: 31 } },
          ],
        ])
      ),
  },
}
