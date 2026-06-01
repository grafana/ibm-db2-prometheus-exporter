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

//go:build !arm64

// Package collector implements IBM DB2 metric collection via database/sql.
package collector

import (
	"database/sql"
	"fmt"
	"log/slog"
	"strconv"
	"sync"

	"github.com/prometheus/client_golang/prometheus"

	_ "github.com/ibmdb/go_ibm_db" // IBM DB2 db driver
)

const (
	namespace = "ibm_db2"

	labelBufferpoolName   = "bufferpool_name"
	labelDatabaseName     = "database_name"
	labelLockState        = "lock_state"
	labelMember           = "member"
	labelHomeHost         = "home_host"
	labelPartitionGroup   = "partition_group"
	labelLogOperationType = "log_operation_type"
	labelLogUsageType     = "log_usage_type"
	labelRowState         = "row_state"
	labelTablespaceName   = "tablespace_name"
	labelTablespaceType   = "tablespace_type"
)

// Collector queries IBM DB2 and emits the collected metrics via prometheus.Collector.
type Collector struct {
	config *Config
	logger *slog.Logger
	dbName string
	db     *sql.DB

	mu       sync.Mutex
	pingFail bool

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
func NewCollector(logger *slog.Logger, cfg *Config) *Collector {
	return &Collector{
		config:   cfg,
		logger:   logger,
		dbName:   cfg.DatabaseName,
		pingFail: false,
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
			[]string{labelDatabaseName, labelMember, labelHomeHost, labelPartitionGroup, labelBufferpoolName},
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
			[]string{labelDatabaseName, labelMember, labelHomeHost, labelPartitionGroup, labelTablespaceName, labelTablespaceType},
			nil,
		),
		logUsage: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "log", "usage"),
			"The disk blocks of active logs space in the database that is not being used by uncommitted transactions. Each block correlates to 4 KiB blocks of storage.",
			[]string{labelDatabaseName, labelMember, labelHomeHost, labelLogUsageType},
			nil,
		),
		logOperations: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "log", "operations_total"),
			"The number of log pages read and written to by the logger.",
			[]string{labelDatabaseName, labelMember, labelHomeHost, labelLogOperationType},
			nil,
		),
		dbUp: prometheus.NewDesc(
			prometheus.BuildFQName(namespace, "", "up"),
			"Metric indicating the status of the exporter collection. 1 indicates that the connection to IBM DB2 was successful, and all available metrics were collected. A 0 indicates that the exporter failed to collect metrics or to connect to IBM DB2.",
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
	c.logger.Debug("Starting to collect metrics.")

	var up float64 = 1
	if err := c.ensureConnection(); err != nil {
		c.logger.Error("Failed to connect to DB2.", "err", err)
		metrics <- prometheus.MustNewConstMetric(c.dbUp, prometheus.GaugeValue, 0, c.dbName)
		return
	}
	defer c.closeConnections()

	if err := c.collectDatabaseMetrics(metrics); err != nil {
		c.logger.Error("Failed to collect general database metrics.", "err", err)
		up = 0
	}

	if err := c.collectApplicationMetrics(metrics); err != nil {
		c.logger.Error("Failed to collect application metrics.", "err", err)
		up = 0
	}

	if err := c.collectLockMetrics(metrics); err != nil {
		c.logger.Error("Failed to collect lock metrics.", "err", err)
		up = 0
	}

	if err := c.collectRowMetrics(metrics); err != nil {
		c.logger.Error("Failed to collect row operation metrics.", "err", err)
		up = 0
	}

	if err := c.collectTablespaceStorageMetrics(metrics); err != nil {
		c.logger.Error("Failed to collect tablespace storage metrics.", "err", err)
		up = 0
	}

	if err := c.collectLogsMetrics(metrics); err != nil {
		c.logger.Error("Failed to collect log metrics.", "err", err)
		up = 0
	}

	if err := c.collectBufferpoolMetrics(metrics); err != nil {
		c.logger.Error("Failed to collect bufferpool metrics.", "err", err)
		up = 0
	}

	metrics <- prometheus.MustNewConstMetric(c.dbUp, prometheus.GaugeValue, up, c.dbName)
}

func (c *Collector) ensureConnection() error {
	c.mu.Lock()
	defer c.mu.Unlock()

	if c.db != nil {
		// this check is done so unit tests can work
		// placed after mutex so threads do not jump over this func
		// can occur when live if Ping takes too long to return
		return nil
	}

	if c.pingFail {
		// ping has failed, continually return err
		return fmt.Errorf("ping is failing: verify DSN is correct and DB2 is running properly")
	}

	db, err := sql.Open("go_ibm_db", c.config.DSN)
	if err != nil {
		return err
	}

	if err = db.Ping(); err != nil {
		// ping failed, set flag to true
		c.pingFail = true
		return err
	}

	c.db = db
	return nil
}

func (c *Collector) closeConnections() {
	if err := c.db.Close(); err != nil {
		c.logger.Error("failing to close connection", "err", err)
	}
	c.db = nil
}

func (c *Collector) collectDatabaseMetrics(metrics chan<- prometheus.Metric) error {
	rows, err := c.db.Query(databaseTableMetricsQuery)
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer func() {
		if err := rows.Close(); err != nil {
			c.logger.Error("failed to close rows", "err", err)
		}
	}()

	for rows.Next() {
		var deadlockCount, connectionsTop float64
		if err := rows.Scan(&connectionsTop, &deadlockCount); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		metrics <- prometheus.MustNewConstMetric(c.connectionsTop, prometheus.CounterValue, connectionsTop, c.dbName)
		metrics <- prometheus.MustNewConstMetric(c.deadlockCount, prometheus.CounterValue, deadlockCount, c.dbName)
	}

	return rows.Err()
}

func (c *Collector) collectApplicationMetrics(metrics chan<- prometheus.Metric) error {
	rows, err := c.db.Query(applicationMetricsQuery)
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer func() {
		if err := rows.Close(); err != nil {
			c.logger.Error("failed to close rows", "err", err)
		}
	}()

	for rows.Next() {
		var applicationActive, applicationExecuting float64
		if err := rows.Scan(&applicationActive, &applicationExecuting); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		metrics <- prometheus.MustNewConstMetric(c.applicationActive, prometheus.GaugeValue, applicationActive, c.dbName)
		metrics <- prometheus.MustNewConstMetric(c.applicationExecuting, prometheus.GaugeValue, applicationExecuting, c.dbName)
	}

	return rows.Err()
}

func (c *Collector) collectLockMetrics(metrics chan<- prometheus.Metric) error {
	rows, err := c.db.Query(lockMetricsQuery)
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer func() {
		if err := rows.Close(); err != nil {
			c.logger.Error("failed to close rows", "err", err)
		}
	}()

	for rows.Next() {
		var lockWaiting, lockActive, lockWaitTime, lockTimeoutCount float64
		if err := rows.Scan(&lockWaiting, &lockActive, &lockWaitTime, &lockTimeoutCount); err != nil {
			return fmt.Errorf("failed to scan row: %w", err)
		}

		metrics <- prometheus.MustNewConstMetric(c.lockUsage, prometheus.GaugeValue, lockWaiting, c.dbName, "waiting")
		metrics <- prometheus.MustNewConstMetric(c.lockUsage, prometheus.GaugeValue, lockActive, c.dbName, "active")
		metrics <- prometheus.MustNewConstMetric(c.lockWaitTime, prometheus.GaugeValue, lockWaitTime, c.dbName)
		metrics <- prometheus.MustNewConstMetric(c.lockTimeoutCount, prometheus.CounterValue, lockTimeoutCount, c.dbName)
	}

	return rows.Err()
}

func (c *Collector) collectRowMetrics(metrics chan<- prometheus.Metric) error {
	rows, err := c.db.Query(rowMetricsQuery)
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer func() {
		if err := rows.Close(); err != nil {
			c.logger.Error("failed to close rows", "err", err)
		}
	}()

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

func (c *Collector) collectTablespaceStorageMetrics(metrics chan<- prometheus.Metric) error {
	rows, err := c.db.Query(tablespaceStorageMetricsQuery)
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer func() {
		if err := rows.Close(); err != nil {
			c.logger.Error("failed to close rows", "err", err)
		}
	}()

	for rows.Next() {
		var iMember int
		var homeHost string
		var tablespaceName string
		var partitionGroup string
		var total, free, used float64
		if err := rows.Scan(&iMember, &homeHost, &partitionGroup, &tablespaceName, &total, &free, &used); err != nil {
			return fmt.Errorf("failed to query metrics: %w", err)
		}
		member := strconv.Itoa(iMember)

		metrics <- prometheus.MustNewConstMetric(c.tablespaceUsage, prometheus.GaugeValue, total, c.dbName, member, homeHost, partitionGroup, tablespaceName, "total")
		metrics <- prometheus.MustNewConstMetric(c.tablespaceUsage, prometheus.GaugeValue, free, c.dbName, member, homeHost, partitionGroup, tablespaceName, "free")
		metrics <- prometheus.MustNewConstMetric(c.tablespaceUsage, prometheus.GaugeValue, used, c.dbName, member, homeHost, partitionGroup, tablespaceName, "used")
	}

	return rows.Err()
}

func (c *Collector) collectLogsMetrics(metrics chan<- prometheus.Metric) error {
	rows, err := c.db.Query(logsMetricsQuery)
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer func() {
		if err := rows.Close(); err != nil {
			c.logger.Error("failed to close rows", "err", err)
		}
	}()

	for rows.Next() {
		var iMember int
		var homeHost string
		var available, used, reads, writes float64
		if err := rows.Scan(&iMember, &homeHost, &available, &used, &reads, &writes); err != nil {
			return fmt.Errorf("failed to query metrics: %w", err)
		}
		member := strconv.Itoa(iMember)

		metrics <- prometheus.MustNewConstMetric(c.logUsage, prometheus.GaugeValue, available, c.dbName, member, homeHost, "available")
		metrics <- prometheus.MustNewConstMetric(c.logUsage, prometheus.GaugeValue, used, c.dbName, member, homeHost, "used")
		metrics <- prometheus.MustNewConstMetric(c.logOperations, prometheus.CounterValue, reads, c.dbName, member, homeHost, "read")
		metrics <- prometheus.MustNewConstMetric(c.logOperations, prometheus.CounterValue, writes, c.dbName, member, homeHost, "write")
	}

	return rows.Err()
}

func (c *Collector) collectBufferpoolMetrics(metrics chan<- prometheus.Metric) error {
	rows, err := c.db.Query(bufferpoolMetricsQuery)
	if err != nil {
		return fmt.Errorf("failed to query metrics: %w", err)
	}
	defer func() {
		if err := rows.Close(); err != nil {
			c.logger.Error("failed to close rows", "err", err)
		}
	}()

	for rows.Next() {
		var bpName string
		var iMember int
		var homeHost string
		var partitionGroup string
		var ratio float64
		var physicalReads, logicalReads float64 // dummy variables to scan into
		if err := rows.Scan(&iMember, &homeHost, &partitionGroup, &bpName, &logicalReads, &physicalReads, &ratio); err != nil {
			return fmt.Errorf("failed to query metrics: %w", err)
		}

		// skip over row if bp hit ratio can't be calculated/is -1
		if ratio == -1 {
			continue
		}
		member := strconv.Itoa(iMember)
		metrics <- prometheus.MustNewConstMetric(c.bufferpoolHitRatio, prometheus.GaugeValue, ratio, c.dbName, member, homeHost, partitionGroup, bpName)
	}

	return rows.Err()
}
