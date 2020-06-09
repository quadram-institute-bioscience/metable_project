#!/bin/bash

echo 'Regenerating "metable.sqlite"'

set -euxo pipefail

if [ -e metable.sqlite ]; then
 rm metable.sqlite
fi
sqlite3 metable.sqlite < schema.sql
sqlite3 metable.sqlite < contigs.sql
sqlite3 metable.sqlite < genes.sql

