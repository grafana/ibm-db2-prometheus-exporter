# **ibm-db2-prometheus-exporter on Windows**

Although this exporter was originally designed to support Linux, it can work on Windows. The steps in this document will outline various differences in the setup process for Windows systems.

**Note**: This document was tested against Windows Server 2022 using PowerShell.

## Prerequisites

The following technologies must be present:

- Git (2.43.0.windows.1)
- Go (1.21.6)
- IBM DB2 (11.5.9)

_The versions listed above were used to test the exporter, but may not represent a necessary version. If difficulties arise, consider upgrading to similar versions._

The final outside technology that must be installed is `Chocolatey`. This will provide the Windows equivalent of `make` so that the exporter binary can be built. Run these 2 commands to install `Chocolatey` and `make` respectively:

```bash
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
chaco install make
```

### ENV Variables

Like in the Linux instructions, the exporter requires that certain environment variables be set:

```bash
set-item -path env:LD_LIBRARY_PATH -value "go\pkg\mod\github.com\ibmdb\clidriver\lib"
set-item -path env:CGO_LDFLAGS -value "-L\<Path to go>\go\pkg\mod\github.com\ibmdb\tmp\clidriver\lib"
set-item -path env:CGO_CFLAGS -value "-I\<Path to go>\go\pkg\mod\github.com\ibmdb\clidriver\include"
set-item -path env:Db2CLP -value "**$**"
```

_Be sure to replace the `<Path to go>` with the path to the `go` directory. This will usually be under the user that Go was installed on._

### DB2 Setup

This guide assumes IBM DB2 is installed and running. If it has not been done already, [initialize the DB2 CLI environment](https://www.ibm.com/support/pages/db21061e-environment-not-initialized-when-running-db2-commands-windows-command-line) explicitly activate the database, and [connect to it](https://www.xtivia.com/blog/how-to-connect-to-a-db2-database/):

```bash
db2cmd -i -w db2clpsetcp
db2 activate database <database>
db2 connect to <database>
```

**Note:** Database activation only affects DB2's ability to report metrics, it does not affect DB2's behavior as a database.

The final requirement for DB2 is to have a user with correct permissions. To give a user `DATAACCESS` permissions, execute the following command:

```bash
db2 grant dataaccess on database to user <username>
```

_Be sure to replace the `<username>` with the name of the user._

## Install DB2 Driver

Similarly to Linux, the [go_ibm_driver](https://github.com/ibmdb/go_ibm_db) should be installed and set-up:

```bash
go install github.com/ibmdb/go_ibm_db/installer@latest
cd go\pkg\mod\github.com\ibmdb\go_ibm_db@<version>\installer
go run setup.go
```

_Be sure to replace the `<version>` with the version that was installed._

## Exporter

After cloning the exporter, modify the `go build` command in the `Makefile` so that the outputted binary is an executable:

```bash
go build -o ./bin/ibm_db2_exporter.exe ./cmd/ibm-db2-exporter/main.go
```

Build the binary and run the exporter, passing in the credentials of a user with permissions enabled:

```bash
make exporter
.\bin\ibm_db2_exporter.exe --db="database" --dsn="DATABASE=database;HOSTNAME=localhost;PORT=50000;UID=username;PWD=password
```

_Be sure to replace each field with information specific to the database and user._

At this point, metrics should be appearing upon running the following command:

```bash
curl <hostname>:9953/metrics
```

If there are no errors in the output of the exporter, the exporter is configured and running correctly. If errors occur, consult the `Troubleshooting` section of the main README file.
