module Lexicon
  class << self
    # @return [Maybe<Semantic::Version>]
    def enabled_version
      if version_table_present?
        Some(
          Semantic::Version.new(
            database
              .query('SELECT version FROM lexicon.version LIMIT 1')
              .to_a.first
              .fetch('version')
          )
        )
      else
        None()
      end
    end

    # @return [Boolean]
    def enabled?
      enabled_version.is_some?
    end

    private

      def database
        ApplicationRecord.connection.raw_connection
      end

      def version_table_present?
        database
          .query("SELECT count(*) AS presence FROM information_schema.tables WHERE table_schema = 'lexicon' AND table_name = 'version'")
          .to_a.first
          .fetch('presence').to_i.positive?
      end
  end
end
