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

package collector

const (

	databaseNoPartitionsMetricsQuery = `SELECT ID, HOME_HOST, DB_PARTITION_NUM FROM TABLE(DB2_GET_INSTANCE_INFO(null,'','','',null)) as T WITH UR`

	databaseTableMetricsQuery = `SELECT
	SUM(connections_top) as connections_top,
	SUM(deadlocks) as deadlock_count
	FROM TABLE(MON_GET_DATABASE(-2)) with ur
	`

	applicationMetricsQuery = `SELECT
	SUM(appls_cur_cons) as application_active,
	SUM(appls_in_db2) as application_executing
	FROM TABLE(MON_GET_DATABASE(-2)) with ur
	`

	lockMetricsQuery = `SELECT
	SUM(num_locks_waiting) as lock_waiting,
	SUM(num_locks_held) as lock_active,
	SUM(lock_wait_time) as lock_wait_time,
	SUM(lock_timeouts) as lock_timeout_count
	FROM TABLE(MON_GET_DATABASE(-2)) with ur
	`

	rowMetricsQuery = `SELECT
	SUM(rows_deleted) as rows_deleted,
	SUM(rows_inserted) as rows_inserted,
	SUM(rows_updated) as rows_updated,
	SUM(rows_read) as rows_read
	FROM TABLE(MON_GET_DATABASE(-2)) with ur
	`

	tablespaceStorageMetricsQuery = `SELECT T.member, I.HOME_HOST , T.tbsp_name, (T.tbsp_total_pages*T.tbsp_page_size) as total_b, (T.tbsp_free_pages*T.tbsp_page_size) as free_b,  (tbsp_used_pages*tbsp_page_size) as used_b FROM TABLE(MON_GET_TABLESPACE('', -2)) as T INNER JOIN  TABLE(DB2_GET_INSTANCE_INFO(null,'','','',null)) as I ON I.ID = T.MEMBER WITH UR`
	
	logsMetricsQuery = `SELECT T.member, I.HOME_HOST , (T.total_log_available / 4000) as blocks_available, (T.total_log_used / 4000) as blocks_used, T.log_reads, T.log_writes FROM TABLE(MON_GET_TRANSACTION_LOG(-2)) AS T INNER JOIN  TABLE(DB2_GET_INSTANCE_INFO(null,'','','',null)) as I ON I.ID = T.MEMBER WITH UR`

	bufferpoolMetricsQuery = `WITH BPMETRICS AS (SELECT
            member,
            bp_name,
                        pool_data_l_reads + pool_temp_data_l_reads +
                        pool_index_l_reads + pool_temp_index_l_reads +
                        pool_xda_l_reads + pool_temp_xda_l_reads as logical_reads,
                        pool_data_p_reads + pool_temp_data_p_reads +
                        pool_index_p_reads + pool_temp_index_p_reads +
                        pool_xda_p_reads + pool_temp_xda_p_reads as physical_reads
                FROM TABLE(MON_GET_BUFFERPOOL('',-2)) AS METRICS
        )
        SELECT RTRIM(BP.member),
            RTRIM(I.HOME_HOST),
            (CASE when BDETAIL.DBPGNAME IS NULL then 'ALL'
        ELSE RTRIM(BDETAIL.DBPGNAME) END) AS DBPGNAME,
        VARCHAR(BP.bp_name,53) AS bp_name,
                BP.logical_reads,
                BP.physical_reads,
                CASE WHEN BP.logical_reads > 0
                        THEN DEC((1 - (FLOAT(BP.physical_reads) / FLOAT(BP.logical_reads))) * 100,5,2)
                        ELSE -1
                END AS HIT_RATIO
        FROM BPMETRICS AS BP, TABLE(DB2_GET_INSTANCE_INFO(null,'','','',null)) as I , syscat.bufferpools as BDETAIL
    WHERE BP.MEMBER = I.ID and BP.bp_name = BDETAIL.BPNAME WITH UR`
	)
