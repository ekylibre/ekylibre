# frozen_string_literal: true

module Lexicon
  module Database
    class Database
      class << self
        def connect(url, verbose: false)
          new(PG.connect(url), verbose: verbose)
        end
      end

      attr_writer :verbose
      # @return [Array<String>]
      attr_reader :search_path

      def initialize(connection, verbose: false)
        @connection = connection
        @search_path = []
        @verbose = verbose

        disable_notices unless verbose
      end

      def verbose?
        @verbose
      end

      def transaction(&block)
        connection.transaction(&block)
      end

      def prepend_search_path(*parts, &block)
        return if block.nil?

        parts.each { |part| ensure_schema(part) }

        with_search_path(*parts, *search_path) do
          block.call
        end
      end

      def on_empty_schema(base_path: [], &block)
        schema = make_random_schema_name

        prepend_search_path(schema, *base_path) do
          block.call(schema)
        end
      ensure
        drop_schema(schema, cascade: true)
      end

      def drop_schema(name, cascade: false)
        cascade = if cascade
                    ' CASCADE'
                  else
                    ''
                  end

        query <<~SQL
          DROP SCHEMA "#{name}"#{cascade};
        SQL
      end

      def make_random_schema_name(prefix = 'lex')
        "#{prefix}_#{rand(0x100000000).to_s(36)}"
      end

      def query(sql, *params, **_options)
        pp sql if verbose?
        @connection.exec_params(sql, *params)
      end

      # @param [#to_s] name
      def ensure_schema(name)
        query(<<~SQL)
          CREATE SCHEMA IF NOT EXISTS "#{name}";
        SQL
      end

      def ensure_schema_empty(name)
        query(<<~SQL)
          DROP SCHEMA IF EXISTS #{name} CASCADE;
        SQL

        ensure_schema(name)
      end

      def copy_data(sql, &block)
        put_data = ->(d) { @connection.put_copy_data(d) }
        @connection.copy_data(sql) { block.call(put_data) }
      end

      private

      # @return [PG::Connection]
      attr_reader :connection

      def disable_notices
        query <<~SQL
              SET client_min_messages TO WARNING;
        SQL
      end

      def with_search_path(*path, &block)
        return if block.nil?

        begin
          saved_path = @search_path
          @search_path = path

          query <<~SQL
                SET search_path TO #{path.map { |part| "\"#{part}\"" }.join(', ')};
          SQL

          result = block.call

          result
        ensure
          path = if saved_path.any?
                   saved_path.map { |part| "\"#{part}\"" }.join(', ')
                 else
                   '" "'
                 end

          query <<~SQL
              SET search_path TO #{path};
          SQL

          @search_path = saved_path
        end
      end
    end
  end
end
