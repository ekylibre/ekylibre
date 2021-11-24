CREATE SCHEMA postgis;
UPDATE pg_extension SET extrelocatable = TRUE WHERE extname = 'postgis';
ALTER EXTENSION postgis SET SCHEMA postgis;
CREATE EXTENSION "uuid-ossp";
