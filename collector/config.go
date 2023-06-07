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
	"errors"
	"strings"
)

type Config struct {
	DSN          string
	DatabaseName string
}

var (
	errNoDSN      = errors.New("DSN must be specified")
	errNoHost     = errors.New("HOSTNAME must be specified in the DSN")
	errNoDatabase = errors.New("DATABASE must be specified in the DSN")
	errNoPort     = errors.New("PORT must be specified in the DSN")
	errNoUID      = errors.New("UID must be specified in the DSN")
	errNoPWD      = errors.New("PWD must be specified in the DSN")
)

func (c *Config) Validate() error {
	if c.DSN == "" {
		return errNoDSN
	}

	d, err := parseDSN(c.DSN)
	if err != nil {
		return err
	}
	c.DatabaseName = d
	return nil
}

// parses values out of DSN config variable
// verifies that they were all present
func parseDSN(dsn string) (string, error) {
	pairs := strings.Split(dsn, ";")

	// loops through pairs, only adds to map if key is assigned a val
	var values = map[string]string{}
	for _, p := range pairs {
		pair := strings.Split(p, "=")
		if len(pair) == 2 {
			values[pair[0]] = pair[1]
		}
	}

	// verify that all parts of the DSN string were present
	if _, ok := values["HOSTNAME"]; !ok {
		return "", errNoHost
	}
	if _, ok := values["DATABASE"]; !ok {
		return "", errNoDatabase
	}
	if _, ok := values["PORT"]; !ok {
		return "", errNoPort
	}
	if _, ok := values["UID"]; !ok {
		return "", errNoUID
	}
	if _, ok := values["PWD"]; !ok {
		return "", errNoPWD
	}

	return values["DATABASE"], nil
}
