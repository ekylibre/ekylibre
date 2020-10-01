# frozen_string_literal: true

module Accountancy
  module Cfonb
    class InterbankTransactionCode

      # @return [String]
      attr_reader :code, :key

      # @param[String] code
      # @param[String] key
      def initialize(code:, key:)
        @code = code
        @key = key
      end

      # @return [String]
      def label
        I18n.t(key, scope: 'interbank_transaction_codes')
      end
    end
  end
end
