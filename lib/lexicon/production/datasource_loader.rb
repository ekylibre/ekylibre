# frozen_string_literal: true

module Lexicon
  module Production
    class DatasourceLoader
      # @param [ShellExecutor] shell
      # @param [Database::Factory] database_factory
      def initialize(shell:, database_factory:)
        @shell = shell
        @database_factory = database_factory
      end

      # @param [Package::Package] package
      # @param [Array<String>, nil] only
      #   If nil, all datasets are loaded.
      #   If present, only listed datasets are loaded.
      #   Structures are ALWAYS loaded
      def load_package(package, only: nil)
        file_sets = package.file_sets.select(&:data_path)

        if !only.nil?
          file_sets = file_sets.select { |fs| only.include?(fs.id) }
        end

        load_structure_files(package.structure_files, schema: lexicon_schema_name(package.version.to_s))

        file_sets.map do |fs|
          Thread.new do
            puts "Loading #{fs.name}"
            load_file(package.data_path(fs))
            puts '[  OK ] '.green + fs.name.yellow
          end
        end.each(&:join)

        lock_tables(package)
      end

      private

      # @return [Database::Factory]
      attr_reader :database_factory
      # @return [ShellExecutor]
      attr_reader :shell

      def load_structure_files(files, schema:)
        database = database_factory.new_instance
        database.prepend_search_path(schema) do
          files.each do |file|
            database.query(file.read)
          end
        end
      end

      # @param [Pathname] data_file
      # @return [Boolean]
      def load_file(data_file)
        if data_file.basename.to_s =~ /\.sql\z/
          load_sql(data_file)
        elsif data_file.basename.to_s =~ /\.sql\.gz\z/
          load_archive(data_file)
        else
          raise StandardError, "Unknown file type: #{data_file.basename}"
        end
      end

      # @param [String] version
      def lexicon_schema_name(version)
        "lexicon__#{version.gsub('.', '_')}"
      end

      # @param [Pathname] archive
      # @return [Boolean]
      def load_archive(archive)
        shell.execute <<~BASH
          cat '#{archive}' | gzip -d | psql '#{database_factory.url}' -v ON_ERROR_STOP=1 -q
        BASH

        true
      end

      # @param [Pathname] file
      # @return [Boolean]
      def load_sql(file)
        shell.execute <<~BASH
          psql '#{database_factory.url}' -v ON_ERROR_STOP=1 -q < '#{file}'
        BASH

        true
      end

      # @param [Package::Package] package
      def lock_tables(package)
        database = database_factory.new_instance

        schema = lexicon_schema_name(package.version.to_s)

        database.prepend_search_path schema do
          database.query <<~SQL
            CREATE OR REPLACE FUNCTION #{schema}.deny_changes()
              RETURNS TRIGGER
            AS $$
              BEGIN
                RAISE EXCEPTION '% denied on % (master data)', TG_OP, TG_RELNAME;
              END;
            $$
            LANGUAGE plpgsql;
          SQL
          package.file_sets.flat_map(&:tables).each do |table_name|
            database.query <<~SQL
              CREATE TRIGGER deny_changes
                BEFORE INSERT
                    OR UPDATE
                    OR DELETE
                    OR TRUNCATE
                ON #{schema}.#{table_name}
                FOR EACH STATEMENT
                  EXECUTE PROCEDURE #{schema}.deny_changes()
            SQL
          end
        end
      end
    end
  end
end
