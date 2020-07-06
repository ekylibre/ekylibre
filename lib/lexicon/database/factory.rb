# frozen_string_literal: true

module Lexicon
  module Database
    class Factory
      class << self
        def from_rails_config
          new(url: db_url, verbose: false)
        end

        private

          def db_url
            user = db_config['username']
            host = db_config['host']
            port = db_config['port'] || '5432'
            dbname = db_config['database']
            password = db_config['password']
            URI.encode("postgresql://#{user}:#{password}@#{host}:#{port}/#{dbname}")
          end

          def db_config
            Rails.application.config.database_configuration[Rails.env.to_s]
          end
      end

      attr_reader :url, :verbose

      def initialize(url:, verbose: false)
        @url = url
        @verbose = verbose
      end

      def new_instance
        ::Lexicon::Database::Database.connect(url, verbose: @verbose)
      end

    end
  end
end
