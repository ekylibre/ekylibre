namespace :duke_reader do
  desc "Grant SELECT on every active tenant schema to the duke_reader role."
  task grant_tenants: :environment do
    role = ENV.fetch('DUKE_READER_ROLE', 'duke_reader')
    conn = ActiveRecord::Base.connection

    # Make sure the role exists; the SQL setup script (db/setup/duke_reader.sql)
    # is the source of truth for its creation.
    exists = conn.select_value(
      conn.quote(role).then { |r| "SELECT 1 FROM pg_roles WHERE rolname = #{r}" }
    )
    abort "Role #{role.inspect} does not exist. Run db/setup/duke_reader.sql first." unless exists

    # Iterate over the tenant schemas Apartment knows about. We do not use
    # Apartment::Tenant.switch! here because we only need the schema names.
    tenant_schemas = Apartment.tenant_names.compact.uniq
    abort "No tenants configured." if tenant_schemas.empty?

    quoted_role = conn.quote_column_name(role)

    tenant_schemas.each do |schema|
      quoted_schema = conn.quote_column_name(schema)
      puts "Granting SELECT on #{schema} to #{role}…"

      conn.execute("GRANT USAGE ON SCHEMA #{quoted_schema} TO #{quoted_role}")
      conn.execute(
        "GRANT SELECT ON ALL TABLES IN SCHEMA #{quoted_schema} TO #{quoted_role}"
      )
      conn.execute(
        "ALTER DEFAULT PRIVILEGES IN SCHEMA #{quoted_schema} " \
        "GRANT SELECT ON TABLES TO #{quoted_role}"
      )
      conn.execute(
        "REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON ALL TABLES " \
        "IN SCHEMA #{quoted_schema} FROM #{quoted_role}"
      )
    end

    puts "Done. #{tenant_schemas.size} tenant schemas updated."
  end

  desc "Verify that duke_reader cannot write anywhere (sanity check)."
  task verify: :environment do
    role = ENV.fetch('DUKE_READER_ROLE', 'duke_reader')
    conn = ActiveRecord::Base.connection

    rows = conn.select_all(<<~SQL)
      SELECT table_schema, table_name, privilege_type
      FROM information_schema.table_privileges
      WHERE grantee = #{conn.quote(role)}
        AND privilege_type IN ('INSERT', 'UPDATE', 'DELETE', 'TRUNCATE')
    SQL

    if rows.any?
      puts "FAIL: #{rows.length} write privileges found:"
      rows.each { |r| puts "  #{r['table_schema']}.#{r['table_name']}: #{r['privilege_type']}" }
      exit 1
    end

    puts "OK: #{role} has no write privileges."
  end
end
