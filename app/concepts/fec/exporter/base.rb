module FEC
  module Exporter
    class Base
      attr_reader :financial_year, :fiscal_position

      def initialize(financial_year, fiscal_position = nil, started_on, stopped_on)
        @financial_year = financial_year
        @fiscal_position = fiscal_position
        @started_on = started_on
        @stopped_on = stopped_on
      end

      def write(path, options = {})
        File.write(path, generate(options))
      end

      # Options are:
      # journal_ids: IDs of journal to extract only
      def generate(options = {})
        build(journals(options[:journal_ids]))
      end

      private

        def journals(ids = nil)
          list = Journal.order(:name)
          list = list.where(id: ids) if ids.present?
          raise 'Needs at least one journal' unless list.any?

          list
        end

        def build(_journals)
          raise NotImplementedError
        end
    end
  end
end
