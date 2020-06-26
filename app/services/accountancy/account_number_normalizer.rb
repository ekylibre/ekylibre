module Accountancy
  class AccountNumberNormalizer
    class NormalizationError < StandardError
      attr_reader :standard_length, :removed, :number

      def initialize(standard_length, number, removed)
        @standard_length = standard_length
        @removed = removed
        @number = number

        super("Normalizing #{number} to #{standard_length} characters would remove #{removed}.")
      end
    end

    DEFAULT_CENTRALIZED_PREFIXES = %w(301 302 303 31 37 401 411 6031 6032 6033 6037 713).freeze

    class << self
      def build(standard_length: Preference[:account_number_digits])
        new(
          standard_length,
          centralized_accounts_prefixes: DEFAULT_CENTRALIZED_PREFIXES
        )
      end

      # @todo Remove with https://gitlab.com/ekylibre/eky/-/issues/719
      # @deprecated
      def build_deprecated_for_account_creation(standard_length: Preference[:account_number_digits])
        new(
          standard_length,
          centralized_accounts_prefixes: %w[401 411]
        )
      end
    end

    attr_reader :standard_length, :centralized_accounts_prefixes

    # @param [Integer] standard_length
    # @param [Array<String>] centralized_accounts_prefixes
    def initialize(standard_length, centralized_accounts_prefixes:)
      @standard_length = standard_length
      @centralized_accounts_prefixes = centralized_accounts_prefixes
    end

    # @param [String|Symbol|Number] number
    # @return [String]
    def normalize!(number)
      number = number.to_s

      if centralized?(number) || number.size == standard_length
        number
      elsif number.size > standard_length
        truncate(number)
      else
        number.ljust(standard_length, "0")
      end
    end

    # @param [String] number
    # @return boolean
    def centralized?(number)
      centralized_accounts_prefixes.any? { |p| number.start_with?(p) }
    end

    # @param [String] number
    # @raise [NormalizationError]
    # @return [String]
    def truncate(number)
      removed = number[standard_length..-1]
      if all_zero?(removed)
        number[0...standard_length]
      else
        raise NormalizationError.new(standard_length, number, removed)
      end
    end

    # @param [String] string
    # @return [Boolean]
    def all_zero?(string)
      string.match(/\A0+\z/).present?
    end
  end
end
