# frozen_string_literal: true

module FEC
  module Check
    class JournalEntry
      attr_reader :journal_entry

      # @return [Array<Symbol>] Non-compliant journal entry attributes
      attr_reader :errors

      ACCOUNTANCY_RISKS_KEY_WORDS = %i[error regulation reimputation reordering fiscal].freeze
      SPECIAL_CARACTERS = %w[\n ; " | & \? < > \= \* \^ \$ \~ \` \t].freeze

      def initialize(journal_entry)
        @journal_entry = journal_entry
        @errors = []
      end

      def validate
        # Journal entry : items with same name
        unless @journal_entry.journal.nature.closure?
          entry_items_with_same_name = @journal_entry.items.pluck(:name).compact.uniq
          add_error(:entry_name_not_uniq) if entry_items_with_same_name.count > 1
        end

        # Journal entry : Created at on weekend or holiday
        created_at_day = @journal_entry.created_at.strftime("%A")
        printed_on_day = @journal_entry.printed_on.strftime("%A")
        if created_at_day.in?(%w[Saturday Sunday]) || printed_on_day.in?(%w[Saturday Sunday])
          add_error(:created_on_free_day)
        elsif Holidays.on(@journal_entry.created_at, :fr).any? || Holidays.on(@journal_entry.printed_on, :fr).any?
          add_error(:created_on_free_day)
        end

        # Journal entry item : Non-uniqueness on account name
        non_uniq_name_account = Account.with_non_uniq_name
        if non_uniq_name_account.any?
          @journal_entry.items.map(&:account).map(&:name).each do |item_account_name|
            if non_uniq_name_account.include?(item_account_name)
              add_error(:entry_item_account_name_not_uniq)
              break
            end
          end
        end

        @journal_entry.items.each do |item|
          # Journal entry item : Reserved keywords on name
          ACCOUNTANCY_RISKS_KEY_WORDS.each do |word|
            if item.name.include?(word.tl)
              add_error(:risky_keyword)
            end
          end
          # Journal entry item : Special caracters on name
          SPECIAL_CARACTERS.each do |word|
            if item.name.include?(word)
              add_error(:special_caracter)
            end
          end
          # Journal entry item : Only whitespace caracters on name
          if item.name.strip.empty?
            add_error(:only_whitespace_caracters)
          end
          # Journal entry item : account with less than 3 caracters
          if item.account_number.length < 3
            add_error(:account_number_with_less_than_3_caracters)
          end

          # Journal entry item: debit and credit = 0
          if (item.real_debit.zero? && item.real_credit.zero?) || (item.real_debit.blank? && item.real_credit.blank?)
            add_error(:zero_value_on_debit_and_credit)
          # Journal entry item : debit and credit > 0
          elsif (item.real_debit > 0 && item.real_credit > 0)
            add_error(:value_on_debit_and_credit)
          end

          # Journal entry item: lettered_at < printed_on
          if item.lettered_at.present? && item.lettered_at.to_date < @journal_entry.printed_on
            add_error(:lettered_at_before_printed_on)
          end

        end

        # Journal entry : Validation date outside current financial year
        fy = @journal_entry.financial_year
        add_error(:out_of_current_financial_year) if @journal_entry.printed_on < fy.started_on || @journal_entry.printed_on > fy.stopped_on

        # Journal entry : Validation date outside printed_on + 60 days
        compare_date = (@journal_entry.validated_at || Date.today)
        add_error(:printed_on_more_than_60_days_ago) if @journal_entry.printed_on + 60.days < compare_date

        # Journal entry : Negative or empty debit or credit
        if @journal_entry.real_debit < 0 || @journal_entry.real_credit < 0 || @journal_entry.real_debit.to_s.empty? || @journal_entry.real_credit.to_s.empty?
          add_error(:negative_or_empty_debit_or_credit)
        end

        # Journal entry : Balance is zero
        if @journal_entry.real_balance != 0.0
          add_error(:journal_entry_balance_is_not_equal_to_zero)
        end

        @errors
      end

      private

        def add_error(error_name)
          return if @errors.include?(error_name)

          @errors << error_name
        end

        class << self
          # Validate journal entry according to FEC standard.
          #
          # @param journal_entry [JournalEntry] Journal entry we want to validate to.
          # @return [Array<Symbol>] Non-compliant journal entry attributes
          # @example Return could be [:negative_credit, :created_at_on_weekend_or_holiday]
          def validate(journal_entry)
            validator = new(journal_entry)
            validator.validate
          end

          def base_errors_name
            %w[journal_entry_balance_is_not_equal_to_zero value_on_debit_and_credit zero_value_on_debit_and_credit entry_name_not_uniq created_on_free_day negative_or_empty_debit_or_credit entry_item_account_name_not_uniq risky_keyword special_caracter only_whitespace_caracters account_number_with_less_than_3_caracters]
          end

          def date_errors_name
            %w[out_of_current_financial_year printed_on_more_than_60_days_ago lettered_at_before_printed_on]
          end

          def errors_name
            base_errors_name + date_errors_name
          end
        end
    end
  end
end
