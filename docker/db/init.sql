CREATE SCHEMA IF NOT EXISTS postgis;

-- Drop+recreate UNIQUEMENT si postgis est installe ailleurs que dans le schema postgis.
-- Deux raisons, dans cet ordre historique :
--   1. l'image kartoza/postgis, employee jusqu'au passage en PostgreSQL 18,
--      reexecutait ce script a chaque restart. Sans la garde, chaque restart
--      faisait DROP EXTENSION postgis CASCADE -> perte des colonnes
--      geometry/geography (shape, geolocation, working_zone, ...) sur tous les
--      tenants ;
--   2. l'image officielle postgis/postgis apporte son propre 10_postgis.sh, qui
--      installe PostGIS dans le schema courant. Ce script-ci est monte en 90-,
--      donc apres : la garde le rattrape et remet l'extension dans le schema
--      `postgis`, celui que schema_search_path et structure.sql attendent.
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

-- Le DROP CASCADE ci-dessus emporte postgis_topology et postgis_tiger_geocoder,
-- que l'image officielle installe avec PostGIS, mais pas fuzzystrmatch : le
-- geocodeur en depend, l'inverse n'est pas vrai. On le retire, ainsi que les
-- schemas vides que les deux extensions laissent derriere elles, pour que la
-- base ne montre que ce que l'application utilise.
DROP EXTENSION IF EXISTS fuzzystrmatch;
DROP SCHEMA IF EXISTS tiger_data CASCADE;
DROP SCHEMA IF EXISTS tiger CASCADE;
DROP SCHEMA IF EXISTS topology CASCADE;
