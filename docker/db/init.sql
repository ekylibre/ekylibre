CREATE SCHEMA postgis;
UPDATE pg_extension SET extrelocatable = TRUE WHERE extname = 'postgis';
ALTER EXTENSION postgis SET SCHEMA postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA postgis;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA postgis;
CREATE EXTENSION IF NOT EXISTS "unaccent" WITH SCHEMA postgis;