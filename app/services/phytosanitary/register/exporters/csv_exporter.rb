# frozen_string_literal: true

require 'csv'

module Phytosanitary
  module Register
    module Exporters
      class CsvExporter < Base
        COLUMNS = ::Phytosanitary::Register::Entry.members.freeze

        def call
          CSV.generate(force_quotes: true) do |csv|
            csv << COLUMNS.map(&:to_s)
            @payload.entries.to_a.each do |entry|
              csv << COLUMNS.map { |c| serialize_value(entry[c]) }
            end
          end
        end
      end
    end
  end
end
