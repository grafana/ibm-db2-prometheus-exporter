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

const (
	databaseTableMetricsQuery = `SELECT
	SUM(connections_top) as connections_top,
	SUM(deadlocks) as deadlock_count
	FROM TABLE(MON_GET_DATABASE(-2))
	`

	applicationMetricsQuery = `SELECT
	SUM(appls_cur_cons) as application_active,
	SUM(appls_in_db2) as application_executing
	FROM TABLE(MON_GET_DATABASE(-2))
	`

	lockMetricsQuery = `SELECT
	SUM(num_locks_waiting) as lock_waiting,
	SUM(num_locks_held) as lock_active,
	SUM(lock_wait_time) as lock_wait_time,
	SUM(lock_timeouts) as lock_timeout_count
	FROM TABLE(MON_GET_DATABASE(-2))
	`

	rowMetricsQuery = `SELECT
	SUM(rows_deleted) as rows_deleted,
	SUM(rows_inserted) as rows_inserted,
	SUM(rows_updated) as rows_updated,
	SUM(rows_read) as rows_read
	FROM TABLE(MON_GET_DATABASE(-2))
	`

	tablespaceStorageMetricsQuery = `SELECT 
	tbsp_name,
	(tbsp_total_pages*tbsp_page_size) as total_b, 
	(tbsp_free_pages*tbsp_page_size) as free_b, 
	(tbsp_used_pages*tbsp_page_size) as used_b
	FROM TABLE(MON_GET_TABLESPACE('', -2))
	`

	logsMetricsQuery = `SELECT 
	member,
	(total_log_available / 4000) as blocks_available,
	(total_log_used / 4000) as blocks_used,
	log_reads,
	log_writes
	FROM TABLE(MON_GET_TRANSACTION_LOG(-2))
	`

	bufferpoolMetricsQuery = `WITH BPMETRICS AS 
	(
		SELECT 
			bp_name,
			pool_data_l_reads + pool_temp_data_l_reads +
			pool_index_l_reads + pool_temp_index_l_reads +
			pool_xda_l_reads + pool_temp_xda_l_reads as logical_reads,
			pool_data_p_reads + pool_temp_data_p_reads +
			pool_index_p_reads + pool_temp_index_p_reads +
			pool_xda_p_reads + pool_temp_xda_p_reads as physical_reads,
			member
		FROM TABLE(MON_GET_BUFFERPOOL('',-2)) AS METRICS
	)
	SELECT
		VARCHAR(bp_name,20) AS bp_name,
		logical_reads,
		physical_reads,
		member,
		CASE WHEN logical_reads > 0
			THEN DEC((1 - (FLOAT(physical_reads) / FLOAT(logical_reads))) * 100,5,2)
			ELSE -1
		END AS HIT_RATIO
	FROM BPMETRICS;
	`
)
