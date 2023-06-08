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
)

type Config struct {
	DSN          string
	DatabaseName string
}

var (
	errNoDSN      = errors.New("DSN must be specified")
	errNoDatabase = errors.New("DATABASE must be specified")
)

func (c *Config) Validate() error {
	if c.DSN == "" {
		return errNoDSN
	}

	if c.DatabaseName == "" {
		return errNoDatabase
	}

	return nil
}
