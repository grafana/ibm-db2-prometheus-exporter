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
			name: "It just works.",
			inputConfig: Config{
				DSN: "HOSTNAME=localhost;PORT=3333;DATABASE=sample;UID=admin;PWD=password",
			},
		},
		{
			name: "no hostname",
			inputConfig: Config{
				DSN: "PORT=3333;DATABASE=sample;UID=admin;PWD=password",
			},
			expectedErr: errNoHost,
		},
		{
			name: "no port",
			inputConfig: Config{
				DSN: "HOSTNAME=localhost;DATABASE=sample;UID=admin;PWD=password",
			},
			expectedErr: errNoPort,
		},
		{
			name: "no database",
			inputConfig: Config{
				DSN: "HOSTNAME=localhost;PORT=3333;UID=admin;PWD=password",
			},
			expectedErr: errNoDatabase,
		},
		{
			name: "no uid",
			inputConfig: Config{
				DSN: "HOSTNAME=localhost;PORT=3333;DATABASE=sample;PWD=password",
			},
			expectedErr: errNoUID,
		},
		{
			name: "no pwd",
			inputConfig: Config{
				DSN: "HOSTNAME=localhost;PORT=3333;DATABASE=sample;UID=admin",
			},
			expectedErr: errNoPWD,
		},
		{
			name:        "no dsn",
			inputConfig: Config{},
			expectedErr: errNoDSN,
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
