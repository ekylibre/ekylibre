# frozen_string_literal: true

module Accountancy
  module Cfonb
    class Importer
      class Result
        def success?
          raise NotImplementedError.new
        end

        def failure?
          !success?
        end

        def and_then(&block)
          self
        end
      end

      class Success < Result
        attr_reader :value

        def initialize(value = nil)
          @value = value
        end

        def success?
          true
        end

        def and_then(&block)
          block.call(value)
        end
      end

      class Failure < Result
        attr_reader :error

        # @param [Error] error
        def initialize(error)
          @error = error
        end

        def success?
          false
        end
      end

      class ImporterError < StandardError
        def initialize(message, **options)
          super(message)

          @options = options
        end

        # @return [String]
        def translated_message
          I18n.t(message, scope: 'errors.messages', **@options)
        end
      end

      class ValidationError < ImporterError; end
      class ModelValidationError < ImporterError
        attr_reader :bank_statement

        # @param [BankStatement] bank_statement
        def initialize(bank_statement)
          super(:model_validation_error)

          @bank_statement = bank_statement
        end
      end

      class << self
        # @return [Accountancy::Cfonb::InterbankTransactionCodeRegistry]
        def build
          new(registry: ::Accountancy::Cfonb::InterbankTransactionCodeRegistry.build)
        end
      end

      attr_reader :registry

      # @param[Accountancy::Cfonb::InterbankTransactionCodeRegistry] registry
      def initialize(registry:)
        @registry = registry
      end

      # @param [Pathname] file
      # @return [Result<BankStatement, Error>]
      def import_bank_statement(file)
        content = parse(file)

        result = valid?(content)

        if result.success?
          process(content)
        else
          result
        end
      rescue StandardError => e
        ElasticAPM.report(e)
        Failure.new(e)
      end

      private

        # @param [Pathname] file
        # @return [SVF::EdiCfonb]
        def parse(file)
          SVF::EdiCfonb.parse(file)
        end

        # @param [SVF::EdiCfonb] content
        # @return [Result]
        def process(content)
          # create cash
          cash_result = find_cash(content.bank_statement_start.account_number)
          return cash_result if cash_result.failure?

          # create bank statement with items
          bank_statement_result = create_bank_statement(content, cash_result.value)

          bank_statement_result.and_then do |bank_statement|
            if bank_statement.save
              Success.new(bank_statement)
            else
              Failure.new(ModelValidationError.new(bank_statement))
            end
          end
        end

        # @param [SVF::EdiCfonb] content
        # @param [Cash] cash
        # @return [Result<BankStatement, Error>]
        def create_bank_statement(content, cash)
          items_result = build_item_attributes(content.entry_details)

          items_result.and_then do |items|
            Success.new(
              BankStatement.new(
                cash: cash,
                number: generate_bank_statement_number(content),
                started_on: cfonb_date_to_date(content.bank_statement_start.balance_date),
                stopped_on: cfonb_date_to_date(content.bank_statement_end.balance_date),
                items_attributes: items
              )
            )
          end
        end

        # @param [SVF::EdiCfonb<entry_detail>] details
        # @return [Result<Hash<BankStatementItem>, Error>]
        def build_item_attributes(details)
          attributes = details.map do |detail|
            if registry.get(detail.interbank_transaction).nil?
              # Return early in case of malformed transaction code
              return Failure.new(ImporterError.new(:no_matching_interbank_code, code: detail.interbank_transaction))
            else
              {
                name: detail.operation_label,
                memo: detail.complements.map(&:complementary_label).map{ |s| s.sub(/\ALIB/, '') }.join(', '),
                transaction_nature: registry.get(detail.interbank_transaction).key,
                balance: to_amount(detail.amount, detail.decimals),
                transfered_on: cfonb_date_to_date(detail.entry_date)
              }
            end
          end
          Success.new(attributes)
        end

        # @param [SVF::EdiCfonb] content
        # @return [String]
        def generate_bank_statement_number(content)
          "#{cfonb_date_to_date(content.bank_statement_start.balance_date)}_#{cfonb_date_to_date(content.bank_statement_end.balance_date)}"
        end

        # @param [String] str
        # @param [String] decimals_str
        # @return [Float]
        def to_amount(str, decimals_str)
          str = str.sub(/^0*/, "")
          last = str[-1]
          norm = if last.ord == 0x7B
                   str[-1] = "0"
                   str
                 elsif last.ord == 0x7D
                   str[-1] = "0"
                   "-" + str
                 elsif 0x41 <= last.ord && last.ord <= 0x49
                   str[-1] = (last.ord - 0x10).chr
                   str
                 elsif 0x4A <= last.ord && last.ord <= 0x52
                   str[-1] = (last.ord - 0x19).chr
                   "-" + str
                 else
                   raise StandardError.new(:no_valid_amount, amount: str)
                 end

          norm.to_f / 10**decimals_str.to_i
        end

        # @param [String] date_str
        # @return [Date]
        def cfonb_date_to_date(date_str)
          Date.strptime(date_str, "%d%m%y")
        end

        # @param [SVF::EdiCfonb] edi
        # @return [Result]
        def valid?(edi)
          if edi.bank_statement_start.nil?
            Failure.new(ValidationError.new(:invalid_uploaded_file))
          elsif multiple_account_numbers?(edi)
            Failure.new(ValidationError.new(:multiple_account_numbers))
          else
            Success.new
          end
        end

        # @param [SVF::EdiCfonb] edi
        # @return Boolean
        def multiple_account_numbers?(edi)
          edi.entry_details
             .map(&:account_number)
             .uniq
             .count > 1
        end

        # @param [SVF::EdiCfonb] edi
        # @return [Result<Cash, Error>]
        def find_cash(account_number)
          target_cash = Cash.pointables.where('iban LIKE ?', "%#{account_number}%")

          if target_cash.empty?
            Failure.new(ImporterError.new(:no_cash_found_for_account, account_number: account_number))
          elsif target_cash.count == 1
            Success.new(target_cash.first)
          else
            Failure.new(ValidationError.new(:expecting_only_one, model: :cash.t, key: account_number, found: target_cash.count))
          end
        end
    end
  end
end
