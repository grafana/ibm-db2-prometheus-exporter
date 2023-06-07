// Copyright  Grafana Labs
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//TODO: add go build tag

package collector

import (
	"database/sql"
	"fmt"
	"strconv"

	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/log/level"
	"github.com/prometheus/client_golang/prometheus"

	_ "github.com/ibmdb/go_ibm_db" // IBM DB2 db driver
)

const (
	namespace = "ibm_db2"

	labelBufferpoolName   = "bufferpool_name"
	labelDatabaseName     = "database_name"
	labelLockState        = "lock_state"
	labelLogMember        = "log_member"
	labelLogOperationType = "log_operation_type"
	labelLogUsageType     = "log_usage_type"
	labelRowState         = "row_state"
	labelTablespaceName   = "tablespace_name"
	labelTablespaceType   = "tablespace_type"
)

func openIBMDBDatabase(connStr string) (*sql.DB, error) {
	return sql.Open("go_ibm_db", connStr)
}

type Collector struct {
	config       *Config
	logger       log.Logger
	openDatabase func(string) (*sql.DB, error)
	dbName       string

	applicationActive    *prometheus.Desc
	applicationExecuting *prometheus.Desc
	connectionsTop       *prometheus.Desc
	deadlockCount        *prometheus.Desc
	lockUsage            *prometheus.Desc
	lockWaitTime         *prometheus.Desc
	lockTimeoutCount     *prometheus.Desc
	bufferpoolHitRatio   *prometheus.Desc
	rowCount             *prometheus.Desc
	tablespaceUsage      *prometheus.Desc
	logUsage             *prometheus.Desc
	logOperations        *prometheus.Desc
	dbUp                 *prometheus.Desc
}

// NewCollector creates a new collector from the given config
func NewCollector(logger log.Logger, cfg *Config) *Collector {
	return &Collector{
		config:       cfg,
		logger:       logger,
		openDatabase: openIBMDBDatabase,
		dbName:       cfg.DatabaseName,
		applicationActive: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "application", "active"),
			"The number of applications that are currently connected to the database.",
			[]string{labelDatabaseName},
			nil,
		),
		applicationExecuting: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "application", "executing"),
			"The number of applications for which the database manager is currently processing a request.",
			[]string{labelDatabaseName},
			nil,
		),
		connectionsTop: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "connections", "top_total"),
			"The maximum number of concurrent connections to the database since the database was activated.",
			[]string{labelDatabaseName},
			nil,
		),
		deadlockCount: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "deadlock", "total"),
			"The total number of deadlocks that have occurred.",
			[]string{labelDatabaseName},
			nil,
		),
		lockUsage: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "lock", "usage"),
			"The number of agents waiting on a lock.",
			[]string{labelDatabaseName, labelLockState},
			nil,
		),
		lockWaitTime: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "lock", "wait_time"),
			"The average wait time for a lock.",
			[]string{labelDatabaseName},
			nil,
		),
		lockTimeoutCount: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "lock", "timeout_total"),
			"The number of timeouts that a request to lock an object occurred instead of being granted.",
			[]string{labelDatabaseName},
			nil,
		),
		bufferpoolHitRatio: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "bufferpool", "hit_ratio"),
			"The percentage of time that the database manager did not need to load a page from disk to service a page request.",
			[]string{labelDatabaseName, labelBufferpoolName},
			nil,
		),
		rowCount: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "row", "total"),
			"The total number of rows inserted, updated, read or deleted.",
			[]string{labelDatabaseName, labelRowState},
			nil,
		),
		tablespaceUsage: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "tablespace", "usage"),
			"The size and usage of table space in bytes.",
			[]string{labelDatabaseName, labelTablespaceName, labelTablespaceType},
			nil,
		),
		logUsage: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "log", "usage"),
			"The disk blocks of active logs pace in the database that is not being used by uncommitted transactions. Each block correlates to 4 KiB blocks of storage.",
			[]string{labelDatabaseName, labelLogMember, labelLogUsageType},
			nil,
		),
		logOperations: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "log", "operations_total"),
			"The number of log pages read and written to by the logger.",
			[]string{labelDatabaseName, labelLogMember, labelLogOperationType},
			nil,
		),
		dbUp: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "", "up"),
			"Metric indicating the status of the exporter collection. 1 indicates that the connection to IBM DB2 was successful, and all available metrics were collected. A 0 indicates that the exporter failed to collect 1 or more metrics, due to an inability to connect to IBM DB2.",
			[]string{labelDatabaseName},
			nil,
		),
	}
}

// Describe emits all metric descriptions of the collector down the given channel
// Implements prometheus.Collector
func (c *Collector) Describe(descs chan<- *prometheus.Desc) {
	descs <- c.applicationActive
	descs <- c.applicationExecuting
	descs <- c.bufferpoolHitRatio
	descs <- c.connectionsTop
	descs <- c.deadlockCount
	descs <- c.lockTimeoutCount
	descs <- c.lockUsage
	descs <- c.lockWaitTime
	descs <- c.logOperations
	descs <- c.logUsage
	descs <- c.rowCount
	descs <- c.tablespaceUsage
	descs <- c.dbUp
}

// Collect collects all metrics for this collector and emits them down the provided channel
// Implements prometheus.Collector
func (c *Collector) Collect(metrics chan<- prometheus.Metric) {
	level.Debug(c.logger).Log("msg", "Starting to collect metrics.")

	var up float64 = 1

	db, err := c.openDatabase(c.config.DSN)
	if err != nil {
		level.Error(c.logger).Log("msg", "Failed to connect to DB2.", "err", err)
		metrics <- prometheus.MustNewConstMetric(c.dbUp, prometheus.GaugeValue, 0, c.dbName)
		return
	}

	defer db.Close()

	if err := c.collectDatabaseMetrics(db, metrics); err != nil {
		level.Error(c.logger).Log("msg", "Failed to collect general database metrics.", "err", err)
		up = 0
	}

	if err := c.collectApplicationMetrics(db, metrics); err != nil {
		level.Error(c.logger).Log("msg", "Failed to collect application metrics.", "err", err)
		up = 0
	}

	if err := c.collectLockMetrics(db, metrics); err != nil {
		level.Error(c.logger).Log("msg", "Failed to collect lock metrics.", "err", err)
		up = 0
	}

	if err := c.collectRowMetrics(db, metrics); err != nil {
		level.Error(c.logger).Log("msg", "Failed to collect row operation metrics.", "err", err)
		up = 0
	}

	if err := c.collectTablespaceStorageMetrics(db, metrics); err != nil {
		level.Error(c.logger).Log("msg", "Failed to collect tablespace storage metrics.", "err", err)
		up = 0
	}

	if err := c.collectLogsMetrics(db, metrics); err != nil {
		level.Error(c.logger).Log("msg", "Failed to collect log metrics.", "err", err)
		up = 0
	}

	if err := c.collectBufferpoolMetrics(db, metrics); err != nil {
		level.Error(c.logger).Log("msg", "Failed to collect bufferpool metrics.", "err", err)
		up = 0
	}

	metrics <- prometheus.MustNewConstMetric(c.dbUp, prometheus.GaugeValue, up, c.dbName)
}

func (c *Collector) collectDatabaseMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	rows, err := db.Query(databaseTableMetricsQuery)
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var deadlock_count, connections_top float64
		if err := rows.Scan(&connections_top, &deadlock_count); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		metrics <- prometheus.MustNewConstMetric(c.connectionsTop, prometheus.CounterValue, connections_top, c.dbName)
		metrics <- prometheus.MustNewConstMetric(c.deadlockCount, prometheus.CounterValue, deadlock_count, c.dbName)
	}

	return rows.Err()
}

func (c *Collector) collectApplicationMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	rows, err := db.Query(applicationMetricsQuery)
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var application_active, application_executing float64
		if err := rows.Scan(&application_active, &application_executing); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		metrics <- prometheus.MustNewConstMetric(c.applicationActive, prometheus.GaugeValue, application_active, c.dbName)
		metrics <- prometheus.MustNewConstMetric(c.applicationExecuting, prometheus.GaugeValue, application_executing, c.dbName)
	}

	return rows.Err()
}

func (c *Collector) collectLockMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	rows, err := db.Query(lockMetricsQuery)
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var lock_waiting, lock_active, lock_wait_time, lock_timeout_count float64
		if err := rows.Scan(&lock_waiting, &lock_active, &lock_wait_time, &lock_timeout_count); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		metrics <- prometheus.MustNewConstMetric(c.lockUsage, prometheus.GaugeValue, lock_waiting, c.dbName, "waiting")
		metrics <- prometheus.MustNewConstMetric(c.lockUsage, prometheus.GaugeValue, lock_active, c.dbName, "active")
		metrics <- prometheus.MustNewConstMetric(c.lockWaitTime, prometheus.GaugeValue, lock_wait_time, c.dbName)
		metrics <- prometheus.MustNewConstMetric(c.lockTimeoutCount, prometheus.CounterValue, lock_timeout_count, c.dbName)
	}

	return rows.Err()
}

func (c *Collector) collectRowMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	rows, err := db.Query(rowMetricsQuery)
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var deleted, inserted, updated, read float64
		if err := rows.Scan(&deleted, &inserted, &updated, &read); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		metrics <- prometheus.MustNewConstMetric(c.rowCount, prometheus.CounterValue, deleted, c.dbName, "deleted")
		metrics <- prometheus.MustNewConstMetric(c.rowCount, prometheus.CounterValue, inserted, c.dbName, "inserted")
		metrics <- prometheus.MustNewConstMetric(c.rowCount, prometheus.CounterValue, updated, c.dbName, "updated")
		metrics <- prometheus.MustNewConstMetric(c.rowCount, prometheus.CounterValue, read, c.dbName, "read")
	}

	return rows.Err()
}

func (c *Collector) collectTablespaceStorageMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	rows, err := db.Query(tablespaceStorageMetricsQuery)
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var tablespace_name string
		var total, free, used float64
		if err := rows.Scan(&tablespace_name, &total, &free, &used); err != nil {
			return fmt.Errorf("failed to query metrics: %w", err)
		}

		metrics <- prometheus.MustNewConstMetric(c.tablespaceUsage, prometheus.GaugeValue, total, c.dbName, tablespace_name, "total")
		metrics <- prometheus.MustNewConstMetric(c.tablespaceUsage, prometheus.GaugeValue, free, c.dbName, tablespace_name, "free")
		metrics <- prometheus.MustNewConstMetric(c.tablespaceUsage, prometheus.GaugeValue, used, c.dbName, tablespace_name, "used")
	}

	return rows.Err()
}

func (c *Collector) collectLogsMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	rows, err := db.Query(logsMetricsQuery)
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var i_member int
		var available, used, reads, writes float64
		if err := rows.Scan(&i_member, &available, &used, &reads, &writes); err != nil {
			return fmt.Errorf("failed to query metrics: %w", err)
		}
		member := strconv.Itoa(i_member)

		metrics <- prometheus.MustNewConstMetric(c.logUsage, prometheus.GaugeValue, available, c.dbName, member, "available")
		metrics <- prometheus.MustNewConstMetric(c.logUsage, prometheus.GaugeValue, used, c.dbName, member, "used")
		metrics <- prometheus.MustNewConstMetric(c.logOperations, prometheus.CounterValue, reads, c.dbName, member, "read")
		metrics <- prometheus.MustNewConstMetric(c.logOperations, prometheus.CounterValue, writes, c.dbName, member, "write")
	}

	return rows.Err()
}

func (c *Collector) collectBufferpoolMetrics(db *sql.DB, metrics chan<- prometheus.Metric) error {
	rows, err := db.Query(bufferpoolMetricsQuery)
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var bp_name string
		var ratio, foo float64
		if err := rows.Scan(&bp_name, &foo, &foo, &foo, &ratio); err != nil {
			return fmt.Errorf("failed to query metrics: %w", err)
		}

		// skip over row if bp hit ratio can't be calculated/is -1
		if ratio == -1 {
			continue
		}

		metrics <- prometheus.MustNewConstMetric(c.bufferpoolHitRatio, prometheus.GaugeValue, ratio, c.dbName, bp_name)
	}

	return rows.Err()
}
