#!/bin/bash
set -e

if [ -z "$DUKE_USER" ] || [ -z "$DUKE_PASSWORD" ]; then
  echo "DUKE_USER or DUKE_PASSWORD not set, skipping read-only role creation."
  exit 0
fi

psql -v ON_ERROR_STOP=1 --host=localhost --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  DO \$\$
  BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DUKE_USER}') THEN
      CREATE ROLE ${DUKE_USER} LOGIN PASSWORD '${DUKE_PASSWORD}';
    END IF;
  END
  \$\$;

  -- Grant connect on database
  GRANT CONNECT ON DATABASE ${POSTGRES_DB} TO ${DUKE_USER};

  -- Grant read-only on all existing schemas and tables
  DO \$\$
  DECLARE
    schema_record RECORD;
  BEGIN
    FOR schema_record IN
      SELECT schema_name FROM information_schema.schemata
      WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast')
    LOOP
      EXECUTE format('GRANT USAGE ON SCHEMA %I TO ${DUKE_USER}', schema_record.schema_name);
      EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA %I TO ${DUKE_USER}', schema_record.schema_name);
      EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA %I GRANT SELECT ON TABLES TO ${DUKE_USER}', schema_record.schema_name);
    END LOOP;
  END
  \$\$;
EOSQL

echo "Read-only role '${DUKE_USER}' created successfully."
