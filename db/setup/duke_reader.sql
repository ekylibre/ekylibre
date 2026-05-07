-- Read-only Postgres role used by the Duke chatbot service.
--
-- Duke connects directly to the Ekylibre database to answer factual
-- questions ("how much Karaté Zeon do I have left?", "what did I do
-- last week?") without going through the Rails API. Writes always go
-- through the API; this role MUST therefore have no write privileges.
--
-- This script creates the role and grants on the `lexicon` and `public`
-- schemas. Per-tenant grants are applied by `rake duke_reader:grant_tenants`
-- (see lib/tasks/duke_reader.rake) so the script is idempotent and safe
-- to re-run when the role evolves.
--
-- Usage:
--   PGPASSWORD=... psql -U ekylibre -d eky_development \
--     -v duke_password='…' -f db/setup/duke_reader.sql
--   bundle exec rake duke_reader:grant_tenants

\set ON_ERROR_STOP on

-- psql doesn't substitute :'var' inside DO blocks (they're dollar-quoted), so
-- we stash the password in a custom GUC first and read it via current_setting().
SELECT set_config('duke.password', :'duke_password', false);

DO $$
DECLARE
  pwd text := current_setting('duke.password');
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'duke_reader') THEN
    EXECUTE format('CREATE ROLE duke_reader LOGIN PASSWORD %L', pwd);
  ELSE
    EXECUTE format('ALTER ROLE duke_reader WITH LOGIN PASSWORD %L', pwd);
  END IF;
END $$;

-- Connect privilege on the active database. We resolve the name at runtime
-- so the script is reusable across environments (eky_development / eky_test
-- / eky_production).
DO $$
BEGIN
  EXECUTE format('GRANT CONNECT ON DATABASE %I TO duke_reader', current_database());
END $$;

-- Lexicon schema is shared across tenants (master data).
GRANT USAGE ON SCHEMA lexicon TO duke_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA lexicon TO duke_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA lexicon
  GRANT SELECT ON TABLES TO duke_reader;

-- Public schema (used as fallback in `search_path`).
GRANT USAGE ON SCHEMA public TO duke_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO duke_reader;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO duke_reader;

-- Defense in depth: explicitly REVOKE any write privilege that might be
-- inherited from PUBLIC role.
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA lexicon FROM duke_reader;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES IN SCHEMA public FROM duke_reader;
