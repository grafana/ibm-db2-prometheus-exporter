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

import (
	"database/sql"
	"database/sql/driver"
	"errors"
	"os"
	"path/filepath"
	"strconv"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/go-kit/kit/log"
	"github.com/prometheus/client_golang/prometheus/testutil"
	"github.com/stretchr/testify/require"
)

func TestCollector_Collect(t *testing.T) {
	t.Run("Metrics match expected", func(t *testing.T) {
		db, mock := createMockDB(t)

		col := NewCollector(log.NewJSONLogger(os.Stdout), &Config{})
		col.db = db

		// reading in & comparing metrics
		f, err := os.Open(filepath.Join("testdata", "all_metrics.prom"))
		require.NoError(t, err)
		defer f.Close()

		require.NoError(t, testutil.CollectAndCompare(col, f))
		require.NoError(t, mock.ExpectationsWereMet())
	})
	t.Run("Metrics have no lint errors", func(t *testing.T) {
		db, mock := createMockDB(t)

		col := NewCollector(log.NewJSONLogger(os.Stdout), &Config{})
		col.db = db

		p, err := testutil.CollectAndLint(col)
		require.NoError(t, err)
		require.Empty(t, p)

		require.NoError(t, mock.ExpectationsWereMet())
	})
	t.Run("All queries fail", func(t *testing.T) {
		db, mock := createQueryErrMockDB(t)

		col := NewCollector(log.NewJSONLogger(os.Stdout), &Config{})
		col.db = db

		// reading in & comparing metrics
		f, err := os.Open(filepath.Join("testdata", "query_failure.prom"))
		require.NoError(t, err)
		defer f.Close()

		require.NoError(t, testutil.CollectAndCompare(col, f))
		require.NoError(t, mock.ExpectationsWereMet())
	})
	t.Run("Database connection fails", func(t *testing.T) {
		col := NewCollector(log.NewJSONLogger(os.Stdout), &Config{})

		openErr := col.ensureConnection()
		require.Error(t, openErr)

		f, err := os.Open(filepath.Join("testdata", "query_failure.prom"))
		require.NoError(t, err)
		defer f.Close()

		// No metrics should be scraped if the database fails to open
		err = testutil.CollectAndCompare(col, f)
		require.NoError(t, err)
	})
}

// ////////////////////
// Helper test funcs //
// ////////////////////
func newRows(t *testing.T, rows [][]string) *sqlmock.Rows {
	numRows := len(rows[0])

	for _, row := range rows {
		require.Equal(t, len(row), numRows, "Number of returned values must be equal for all rows")
	}

	cols := []string{}
	for i := 0; i < numRows; i++ {
		cols = append(cols, strconv.FormatInt(int64(i), 10))
	}

	sqlRows := sqlmock.NewRows(cols)

	for _, row := range rows {
		rowVals := []driver.Value{}
		for _, s := range row {
			rowVals = append(rowVals, sql.NullString{
				String: s,
				Valid:  true,
			})
		}

		sqlRows.AddRow(rowVals...)
	}

	return sqlRows
}

// represents a mock db
// returns predefined results for queries
func createMockDB(t *testing.T) (*sql.DB, sqlmock.Sqlmock) {
	t.Helper()

	db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherEqual))
	require.NoError(t, err)

	// (sum) connections_top, deadlock_count
	mock.ExpectQuery(databaseTableMetricsQuery).WillReturnRows(
		newRows(t, [][]string{
			{"18", "3"},
		}),
	).RowsWillBeClosed()

	// (sum) application_active, application_executing
	mock.ExpectQuery(applicationMetricsQuery).WillReturnRows(
		newRows(t, [][]string{
			{"12", "7"},
		}),
	)

	// (sum) lock_waiting, lock_active, lock_wait_time, lock_timeout_count
	mock.ExpectQuery(lockMetricsQuery).WillReturnRows(
		newRows(t, [][]string{
			{"3", "5", "44", "2"},
		}),
	)

	// (sum) rows_deleted, rows_inserted, rows_updated, rows_read
	mock.ExpectQuery(rowMetricsQuery).WillReturnRows(
		newRows(t, [][]string{
			{"33", "44", "55", "66"},
		}),
	)

	// (rows) tbsp_name, total_b, free_b, used_b
	mock.ExpectQuery(tablespaceStorageMetricsQuery).WillReturnRows(
		newRows(t, [][]string{
			{"tbsp1", "333", "444", "555"},
			{"tbsp2", "666", "777", "888"},
			{"tbsp3", "999", "111", "222"},
		}),
	)

	// (rows) member, blocks_available, blocks_used, log_reads, log_writes
	mock.ExpectQuery(logsMetricsQuery).WillReturnRows(
		newRows(t, [][]string{
			{"1", "22", "33", "4", "5"},
			{"2", "66", "77", "8", "9"},
			{"3", "11", "22", "3", "4"},
		}),
	)

	// (rows) bp_name, logical_reads, physical_reads, member, hit_ratio
	mock.ExpectQuery(bufferpoolMetricsQuery).WillReturnRows(
		newRows(t, [][]string{
			{"bp1", "0", "0", "1", "11.22"},
			{"bp2", "0", "0", "2", "33.44"},
			{"bp3", "0", "0", "3", "55.66"},
			{"bp4", "0", "0", "4", "77.88"},
		}),
	)

	mock.ExpectClose()

	return db, mock
}

func createQueryErrMockDB(t *testing.T) (*sql.DB, sqlmock.Sqlmock) {
	t.Helper()

	queryErr := errors.New("the query failed for inexplicable reasons")

	db, mock, err := sqlmock.New(sqlmock.QueryMatcherOption(sqlmock.QueryMatcherEqual))
	require.NoError(t, err)

	mock.ExpectQuery(databaseTableMetricsQuery).WillReturnError(queryErr)
	mock.ExpectQuery(applicationMetricsQuery).WillReturnError(queryErr)
	mock.ExpectQuery(lockMetricsQuery).WillReturnError(queryErr)
	mock.ExpectQuery(rowMetricsQuery).WillReturnError(queryErr)
	mock.ExpectQuery(tablespaceStorageMetricsQuery).WillReturnError(queryErr)
	mock.ExpectQuery(logsMetricsQuery).WillReturnError(queryErr)
	mock.ExpectQuery(bufferpoolMetricsQuery).WillReturnError(queryErr)

	mock.ExpectClose()

	return db, mock
}
