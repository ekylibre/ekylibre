module Ekylibre
  class LoansExchanger < ActiveExchanger::Base
    # TODO: add this class in common class of Exchanger Errors
    class UniqueResultExpectedError < StandardError; end
    category :accountancy
    vendor :ekylibre

    # Imports fixed assets into fixed assets DB
    # filename example : EMPRUNTS.CSV
    # separator is ';' with headers and encoding is UTF-8
    # Columns are:
    #  0 - A: number
    #  1 - B: name
    #  2 - C: amount
    #  3 - D: cash_name
    #  4 - E: lender_name
    #  5 - F: interest_percentage
    #  6 - G: insurance_percentage
    #  7 - H: insurance_repayment_method
    #  8 - I: repayment_method
    #  9 - J: shift_method
    #  10 - K: ongoing_at
    #  11 - L: started_on
    #  12 - M: repayment_period
    #  13 - N: repayment_duration.
    #  14 - O: shift_duration
    #  15 - P: loan_account_number.
    #  16 - Q: loan_account_name
    #  17 - R: interest_account_number
    #  18 - S: interest_account_name
    #  19 - T: insurance_account_number
    #  20 - U: insurance_account_name
    #  21 - V: initial_releasing_amount #boolean
    #  22 - W: accountable_repayments_started_on
    #  23 - X : use_bank_guarantee

    NORMALIZATION_CONFIG = [
      { col: 0, name: :number, type: :string, constraint: :not_nil },
      { col: 1, name: :name, type: :string, constraint: :not_nil },
      { col: 2, name: :amount, type: :float, constraint: :greater_or_equal_to_zero },
      { col: 3, name: :cash_name, type: :string, constraint: :not_nil },
      { col: 4, name: :lender_name, type: :string, constraint: :not_nil },
      { col: 5, name: :interest_percentage, type: :float, constraint: :not_nil },
      { col: 6, name: :insurance_percentage, type: :float },
      { col: 7, name: :insurance_repayment_method, type: :string },
      { col: 8, name: :repayment_method, type: :string },
      { col: 9, name: :shift_method, type: :string },
      { col: 10, name: :ongoing_at, type: :date },
      { col: 11, name: :started_on, type: :date, constraint: :not_nil },
      { col: 12, name: :repayment_period, type: :string, constraint: :not_nil },
      { col: 13, name: :repayment_duration, type: :integer, constraint: :not_nil },
      { col: 14, name: :shift_duration, type: :integer, constraint: :not_nil },
      { col: 15, name: :loan_account_number, type: :string, constraint: :not_nil },
      { col: 16, name: :loan_account_name, type: :string },
      { col: 17, name: :interest_account_number, type: :string, constraint: :not_nil },
      { col: 18, name: :interest_account_name, type: :string },
      { col: 19, name: :insurance_account_number, type: :string },
      { col: 20, name: :insurance_account_name, type: :string },
      { col: 21, name: :initial_releasing_amount, type: :integer },
      { col: 22, name: :accountable_repayments_started_on, type: :date },
      { col: 23, name: :use_bank_guarantee, type: :integer },
      { col: 24, name: :bank_guarantee_amount, type: :float },
      { col: 25, name: :bank_guarantee_account_number, type: :string },
      { col: 26, name: :bank_guarantee_account_name, type: :string }
    ].freeze

    # accounts to check
    ACCOUNT_NUMBER_PROPERTIES = %w[insurance_account interest_account loan_account bank_guarantee_account].freeze

    def check
      rows, errors = parse_file(file)
      w.count = rows.size

      valid = errors.all?(&:empty?)
      if valid == false
        w.error "The file is invalid: #{errors}"
        return false
      end

      rows.each_with_index do |row, index|
        line_number = index + 2
        # w.check_point

        # check cash presence
        cash = Cash.where("name ILIKE ?", row.cash_name + '%')
        unless cash.any?
          w.error "No cash are present in DB : #{row.cash_name} in line : #{line_number}.You must create it before importing loans".red
          valid = false
        end

        # check correct insurance_repayment_method
        if row.insurance_repayment_method.present? && !row.insurance_repayment_method.in?(Loan.insurance_repayment_method.values)
          w.error "Errors on insurance_repayment_method : #{row.insurance_repayment_method} in line : #{line_number}. Values msut be one of #{Loan.insurance_repayment_method.values}".red
          valid = false
        end

        # check correct repayment_method
        if row.repayment_method.present? && !row.repayment_method.in?(Loan.repayment_method.values)
          w.error "Errors on insurance_repayment_method : #{row.repayment_method} in line : #{line_number}. Values msut be one of #{Loan.repayment_method.values}".red
          valid = false
        end

        # check correct shift_method
        if row.shift_method.present? && !row.shift_method.in?(Loan.shift_method.values)
          w.error "Errors on shift_method : #{row.shift_method} in line : #{line_number}. Values msut be one of #{Loan.shift_method.values}".red
          valid = false
        end

        # check correct repayment_period
        if row.repayment_period.present? && !row.repayment_period.in?(Loan.repayment_period.values)
          w.error "Errors on shift_method : #{row.repayment_period} in line : #{line_number}. Values msut be one of #{Loan.repayment_period.values}".red
          valid = false
        end

        # check asset account must exist in DB
        ACCOUNT_NUMBER_PROPERTIES.each do |property|
          if row.send(property + '_number').present?
            account = find_or_create_account(row.send(property + '_number'), row.send(property + '_name'))
            if account.nil?
              w.error "No way to have matching asset account in DB or Nomenclature (#{row.send(property + '_number')}) to build fixed asset in line : #{line_number}"
              valid = false
            end
          end
        end

        # accountable_repayments_started_on chech if financial year opened
        if row.accountable_repayments_started_on.present?
          fy = FinancialYear.on(row.accountable_repayments_started_on)
          unless fy.opened?
            w.error "No financial year opened at #{row.accountable_repayments_started_on} in line : #{line_number}"
            valid = false
          end
        end

        w.info "#{line_number} - #{valid}".green
        w.check_point

      end
      w.info "End validation : #{valid}".yellow
      valid
    end

    def import
      rows, _errors = parse_file(file)
      w.count = rows.size

      rows.each_with_index do |row, index|
        line_number = index + 2
        w.info "Loan started : #{row.number} | #{row.name.inspect.yellow}"

        # computed state link to started on and Financial year
        # ongoing if started_on before a financial year opened
        fy = FinancialYear.on(row.started_on)
        if fy && fy.opened?
          state = 'draft'
        elsif row.started_on > FinancialYear.current.started_on
          state = 'draft'
        else
          state = 'ongoing'
        end

        # add general loan attributes
        loan_attributes = {
          name: row.name,
          started_on: row.started_on,
          ongoing_at: (row.ongoing_at.present? ? row.ongoing_at : nil),
          accountable_repayments_started_on: (row.accountable_repayments_started_on.present? ? row.accountable_repayments_started_on : nil),
          amount: row.amount,
          cash: Cash.where("name ILIKE ?", row.cash_name + '%').first,
          lender: find_or_create_lender(row.lender_name),
          interest_percentage: row.interest_percentage,
          loan_account: find_or_create_account(row.loan_account_number),
          interest_account: find_or_create_account(row.interest_account_number),
          repayment_duration: row.repayment_duration,
          repayment_method: row.repayment_method,
          repayment_period: row.repayment_period,
          initial_releasing_amount: ((row.initial_releasing_amount.present? && row.initial_releasing_amount == 1) ? true : false),
          insurance_percentage: 0.0,
          use_bank_guarantee: false,
          shift_duration: 0,
          state: state,
          provider: provider_value(number: row.number)
        }

        # add insurance attributes for loan if present
        if row.insurance_percentage.present? && row.insurance_percentage > 0.0 && row.insurance_account_number.present? && row.insurance_repayment_method.present?
          loan_attributes[:insurance_percentage] = row.insurance_percentage
          loan_attributes[:insurance_account] = find_or_create_account(row.insurance_account_number)
          loan_attributes[:insurance_repayment_method] = row.insurance_repayment_method
        end

        # add use_bank_guarantee attributes for loan if present
        if row.use_bank_guarantee == 1 && row.bank_guarantee_amount.presence? && row.bank_guarantee_account_number.presence?
          loan_attributes[:use_bank_guarantee] = true
          loan_attributes[:bank_guarantee_account] = find_or_create_account(row.bank_guarantee_account_number)
          loan_attributes[:bank_guarantee_amount] = row.bank_guarantee_amount
        end

        # add shift_duration if > 0
        if row.shift_duration.present? && row.shift_duration > 0 && row.shift_method.present?
          loan_attributes[:shift_duration] = row.shift_duration
          loan_attributes[:shift_method] = row.shift_method
        end

        # Check existing asset (name && started_on && depreciable_amount)
        loan = find_loan_by_provider(row.number)

        # Update, Nothing or Create asset
        if loan && loan.updateable?
          loan.update!(loan_attributes)
          w.info "Loan updated : #{loan.name.inspect.yellow}"
        elsif loan && !loan.updateable?
          w.info "Loan are not updateable : #{loan.name.inspect.red}"
        else
          loan = Loan.create!(loan_attributes)
          w.info "Loan created : #{loan.name.inspect.green}"
        end

        w.check_point
      end
    end

    private

      # @return [Accountancy::AccountNumberNormalizer]
      def number_normalizer
        @number_normalizer ||= Accountancy::AccountNumberNormalizer.build
      end

      # @param [String] acc_number
      # @param [String] acc_name
      # @return [Account]
      def find_or_create_account(acc_number, acc_name = nil)
        Maybe(find_or_create_account_by_number(acc_number, acc_name))
          .or_raise
      end

      # @param [String] acc_number
      # @param [String] acc_name
      # @return [Account]
      def find_or_create_account_by_number(acc_number, acc_name = nil)
        normalized = account_normalizer.normalize!(acc_number)

        Maybe(Account.find_by(number: normalized))
          .recover { create_account(acc_number, normalized, acc_name) }
          .or_raise
      end

      # @param [String] acc_number
      # @param [String] acc_name
      # @return [Account]
      def create_account(acc_number, acc_number_normalized, acc_name = nil)
        attrs = {
          name: acc_name,
          number: acc_number_normalized,
          provider: provider_value(account_number: acc_number)
        }
        Account.create!(attrs)
      end

      # @param [String] name
      # @return [Entity, nil]
      def find_or_create_lender(name)
        Maybe(Entity.find_by(full_name: name))
          .recover {Entity.find_by(last_name: name)}
          .recover {find_entity_by_name(name)}
          .recover { Entity.create!(
            active: true,
            supplier: true,
            last_name: name.mb_chars.capitalize,
            nature: :organization,
            provider: provider_value(entity_name: name)
          ) }
          .or_raise
      end

      # @param [String] name
      # @return [Entity, nil]
      def find_entity_by_name(name)
        unwrap_one('entity') {
          Maybe(Entity.where("full_name ILIKE ?", name + '%'))
            .recover{ Entity.where("first_name ILIKE ?", name + '%') }
            .recover{ Entity.where("last_name ILIKE ?", name + '%') }
            .or_else([])
        }
      end

      # @param [String]
      # @return [FixedAsset, nil]
      def find_loan_by_provider(code)
        unwrap_one('loan') do
          Loan.of_provider_name(self.class.vendor, provider_name)
                 .of_provider_data(:number, code)
        end
      end

    protected

      def unwrap_one(name, exact: false, &block)
        results = block.call
        size = results.size
        if size > 1
          raise UniqueResultExpectedError.new("Expected only one #{name}, got #{size}")
        elsif exact && size == 0
          raise UniqueResultExpectedError.new("Expected only one #{name}, got none")
        else
          results.first
        end
      end

      # @return [Accountancy::AccountNumberNormalizer]
      def account_normalizer
        @account_normalizer ||= Accountancy::AccountNumberNormalizer.build
      end

      # @return [Import]
      def import_resource
        @import_resource ||= Import.find(options[:import_id])
      end

      def provider_value(**data)
        { vendor: self.class.vendor, name: provider_name, id: import_resource.id, data: data }
      end

      def provider_name
        :loans
      end

      def parse_file(file)
        rows = ActiveExchanger::CsvReader.new(col_sep: ';').read(file)
        parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

        parser.normalize(rows)
      end

  end
end
