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
	"testing"

	"github.com/stretchr/testify/require"
)

func TestConfig_Validate(t *testing.T) {
	testCases := []struct {
		name        string
		inputConfig Config
		expectedErr error
	}{
		{
			name: "valid config",
			inputConfig: Config{
				DSN:          "DATABASE=database;HOSTNAME=localhost;PORT=3333;UID=admin;PWD=password",
				DatabaseName: "database",
			},
			expectedErr: nil,
		},
		{
			name: "no database",
			inputConfig: Config{
				DSN: "DATABASE=database;HOSTNAME=localhost;PORT=3333;UID=admin;PWD=password",
			},
			expectedErr: errNoDatabase,
		},
		{
			name: "no dsn",
			inputConfig: Config{
				DatabaseName: "database",
			},
			expectedErr: errNoDSN,
		},
		{
			name: "empty DSN",
			inputConfig: Config{
				DSN:          "",
				DatabaseName: "database",
			},
			expectedErr: errNoDSN,
		},
		{
			name: "empty DatabaseName",
			inputConfig: Config{
				DSN:          "DATABASE=database;HOSTNAME=localhost;PORT=3333;UID=admin;PWD=password",
				DatabaseName: "",
			},
			expectedErr: errNoDatabase,
		},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			err := tc.inputConfig.Validate()
			if tc.expectedErr != nil {
				require.Equal(t, tc.expectedErr, err)
			} else {
				require.Nil(t, err)
			}
		})
	}
}
