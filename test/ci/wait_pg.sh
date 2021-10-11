#!/bin/bash

RETRIES=${RETRIES:-300} # 5 minutes
until psql -h "${1:-127.0.0.1}" -U "${2:-postgres}" -d "${3:-postgres}" -c "select 1" > /dev/null 2>&1 || [ "$RETRIES" -eq 0 ]; do
  echo "Waiting for postgres server, $((RETRIES--)) remaining attempts..."
  sleep 1
done

echo "PostgreSQL is up and running"