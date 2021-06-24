# frozen_string_literal: true

module Accountancy
  module Cfonb
    class InterbankTransactionCodeRegistry
      DEFAULT_FILE_NAME = 'interbank_transaction_codes.csv'
      PARSER_CONFIG = [
        { col: 0, name: :code, type: :string },
        { col: 1, name: :label, type: :string }
      ].freeze

      class << self
        def build
          new(file: default_file)
        end

        private

          def default_file
            Pathname.new(__dir__).join(DEFAULT_FILE_NAME)
          end
      end

      # @return [Hash<String, Accountancy::Cfonb::InterbankTransactionCode>]
      attr_reader :interbank_codes

      # @param [Pathname] file
      def initialize(file:)
        rows = ActiveExchanger::CsvReader.new(col_sep: ',').read(file)
        parser = ActiveExchanger::CsvParser.new(PARSER_CONFIG)
        rows, errors = parser.normalize(rows)
        @interbank_codes = rows.map do |row|
          [row.code, InterbankTransactionCode.new(code: row.code, key: row.label)]
        end.to_h
      end

      # @param [String] code
      # @return [InterbankTransactionCode, nil]
      def get(code)
        interbank_codes[code]
      end
    end
  end
end
