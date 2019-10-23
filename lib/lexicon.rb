module Lexicon
  SCHEMA = 'lexicon'.freeze
  DISABLED_SCHEMA = '___lexicon'.freeze

  class << self
    def connection
      ActiveRecord::Base.connection
    end

    def structure_script
      Rails.root.join('db', 'lexicon', 'structure.sql')
    end

    def data_script
      if Rails.env == 'test'
        Rails.root.join('test', 'fixture-files', 'data.sql')
      else
        Rails.root.join('db', 'lexicon', 'data.sql')
      end
    end

    def clear!
      connection.execute "DROP SCHEMA IF EXISTS #{SCHEMA}, #{DISABLED_SCHEMA} CASCADE"
    end

    def disable!
      if Apartment.connection.schema_exists?(SCHEMA)
        connection.execute "ALTER SCHEMA #{SCHEMA} RENAME TO #{DISABLED_SCHEMA}"
      end
    end

    def enable!
      if Apartment.connection.schema_exists?(DISABLED_SCHEMA)
        connection.execute "ALTER SCHEMA #{DISABLED_SCHEMA} RENAME TO #{SCHEMA}"
      else
        load_structure!
      end
    end

    def execute_script(script, message)
      puts "== #{message}: migrating ==".ljust(79, '=').cyan
      start = Time.now
      db = Rails.application.config.database_configuration[Rails.env].with_indifferent_access
      db_url = Shellwords.escape("postgresql://#{db[:username]}:#{db[:password]}@#{db[:host]}:#{db[:port] || 5432}/#{db[:database]}")
      `echo 'SET SEARCH_PATH TO #{SCHEMA};' | cat - #{script.to_s} | psql --dbname=#{db_url}`
      puts "== #{message}: migrated (#{(Time.now - start).round(4)}s) ==".ljust(79, '=').cyan
      puts ''
    end

    def load!
      connection.execute "CREATE SCHEMA #{SCHEMA}"
      execute_script(structure_script, 'Add tables in lexicon schema')
      execute_script(data_script, 'Load data of lexicon') if data_script.exist?
      lock!
    end

    def load_structure!
      connection.execute "CREATE SCHEMA #{SCHEMA}"
      execute_script(structure_script, 'Add tables in lexicon schema')
      lock!
    end

    def reload!
      clear!
      load!
    end

    # Adds trigger on lexicon table to prevent changes in the rows by AR or
    # simple SQL queries.
    def lock!
      connection.execute("CREATE OR REPLACE FUNCTION #{SCHEMA}.deny_changes() RETURNS TRIGGER AS $$ BEGIN RAISE EXCEPTION '% denied on % (master data)', TG_OP, TG_RELNAME; END; $$ LANGUAGE plpgsql;")
      tables = connection.select_values("SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = '#{SCHEMA}'")
      tables.each do |table|
        connection.execute "CREATE TRIGGER deny_changes BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE ON #{SCHEMA}.#{table} FOR EACH STATEMENT EXECUTE PROCEDURE #{SCHEMA}.deny_changes()"
      end
    end
  end
end
