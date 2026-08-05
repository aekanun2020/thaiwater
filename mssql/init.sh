#!/usr/bin/env bash
set -euo pipefail

/opt/mssql-tools18/bin/sqlcmd \
  -S mssql -U sa -P "${MSSQL_SA_PASSWORD}" -C -b \
  -i /workspace/init.sql

