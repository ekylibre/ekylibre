CREATE SCHEMA IF NOT EXISTS postgis;

-- Drop+recreate UNIQUEMENT si postgis est installe ailleurs que dans le schema postgis.
-- L'image kartoza/postgis reexecute ce script a chaque restart : sans cette garde,
-- chaque restart faisait DROP EXTENSION postgis CASCADE -> perte des colonnes
-- geometry/geography (shape, geolocation, working_zone, ...) sur tous les tenants.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_extension e
    JOIN pg_namespace n ON n.oid = e.extnamespace
    WHERE e.extname = 'postgis' AND n.nspname <> 'postgis'
  ) THEN
    DROP EXTENSION postgis CASCADE;
  END IF;
END $$;

CREATE EXTENSION IF NOT EXISTS postgis SCHEMA postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA postgis;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA postgis;
CREATE EXTENSION IF NOT EXISTS "unaccent" WITH SCHEMA postgis;
CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA postgis;
