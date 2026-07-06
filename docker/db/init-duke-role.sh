#!/bin/bash
# Cree un role PostgreSQL lecture seule pour Duke (assistant chatbot).
#
# ATTENTION : ce script est SOURCE (pas execute) par le docker-entrypoint de
# kartoza/postgis (`for f in /docker-entrypoint-initdb.d/*; do . $f; done` dans
# /scripts/env-data.sh). Un `exit N` remonterait au shell parent et
# interromprait l'initialisation Postgres -> pas de foreground postgres ->
# container en boucle de redemarrage. On evite donc tout `exit` : quand les
# vars Duke sont absentes, on log et on ne fait rien.
set -e

if [ -n "$DUKE_USER" ] && [ -n "$DUKE_PASSWORD" ]; then
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
else
  echo "DUKE_USER or DUKE_PASSWORD not set, skipping read-only role creation."
fi
