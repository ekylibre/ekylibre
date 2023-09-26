# frozen_string_literal: true

module Listo
  class OdTxtExchanger < ActiveExchanger::Base
    category :accountancy
    vendor :listo

    #  0 - A: JournalCode : "OD"
    #  1 - B: JournalLib : "OPERATIONS DIVERSES"
    #  2 - C: EcritureNum : ""
    #  3 - D: EcritureDate : "31072023"
    #  4 - E: CompteNum : "421000"
    #  5 - F: CompteLib : ""
    #  6 - G: CompAuxNum : ""
    #  7 - H: CompAuxLib : ""
    #  8 - I: PieceRef : ""
    #  9 - J: PieceDate : ""
    #  10 - K: EcritureLib : "PERSONNEL - REMUNERATIONS DUES"
    #  11 - L: Debit : "0"
    #  12 - M: Credit : "2981.42"
    #  13 - N: EcritureLet : ""
    #  14 - O: DateLet : ""
    #  15 - P: ValidDate : ""
    #  16 - Q: MontantDevise
    #  17 - R: Idevise
    #  18 - S: AnalytiqueCode
    #  19 - T: AnalytiqueLib
    #  20 - U: Nom Prenom

    NORMALIZATION_CONFIG = [
      { col: 3, name: :printed_on, type: :fr_date },
      { col: 4, name: :account_number, type: :string },
      { col: 10, name: :entry_item_name, type: :string },
      { col: 11, name: :debit_amount, type: :float },
      { col: 12, name: :credit_amount, type: :float }
    ].freeze

    def check
      # Imports OD journal entries into journal to make accountancy in CSV format
      # From local software LISTO
      # filename example : 2023-07-01-2023-08-01-Ecriture-de-paie-EKYLIBRE-00045-80853428300045.csv
      # separator is ';' and encoding is UTF-8

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

        fy_start = FinancialYear.at(row.printed_on)
        unless fy_start
          w.error "FinancialYear does not exist for #{row.printed_on} in line : #{line_number} - #{valid}".red
          valid = false
        end

        if row.debit_amount.present? && row.credit_amount.present? && (row.debit_amount - row.credit_amount) == 0.0
          w.error "Errors on amount in line : #{line_number} - #{valid}".red
          valid = false
        end

        if row.account_number.blank? || row.printed_on.blank? || row.entry_item_name.blank?
          w.error "Errors on account (#{row.account_number}) or printed_on (#{row.printed_on.to_s}) or item_name (#{row.entry_item_name}) in line : #{line_number} - #{valid}".red
          valid = false
        end

        w.info "#{line_number} - #{valid}".green
      end
      w.info "End validation : #{valid}".yellow
      valid
    end

    def import
      rows, _errors = parse_file(file)
      w.count = rows.size

      # find or create a unique journal for LISTO
      journal = find_or_create_journal('LIST', 'Import LISTO', 'various')

      entries = {}
      rows.each_with_index do |row, index|
        line_number = index + 2

        # case of negative values
        if row.debit_amount.present? && row.debit_amount < 0.0
          row.credit_amount = -row.debit_amount
          row.debit_amount = 0.0
        end

        if row.credit_amount.present? && row.credit_amount < 0.0
          row.debit_amount = -row.credit_amount
          row.credit_amount = 0.0
        end

        if row.credit_amount.blank?
          row.credit_amount = 0.0
        elsif row.debit_amount.blank?
          row.debit_amount = 0.0
        end

        number = row.printed_on.strftime("%Y%m%d")

        w.info "--------------------index : #{index} | number : #{number}--------------------------"

        # create entry attributes
        entries[number] ||= {
          printed_on: row.printed_on,
          journal: journal,
          number: number,
          currency: journal.currency,
          provider: provider_value,
          items_attributes: {}
        }

        # create account
        account = find_or_create_account(row.account_number, row.entry_item_name)
        w.info "account created: #{account.label.inspect.green}"

        # create entry item attributes
        id = (entries[number][:items_attributes].keys.max || 0) + 1
        entries[number][:items_attributes][id] = {
          real_debit: row.debit_amount.to_f,
          real_credit: row.credit_amount.to_f,
          account: account,
          name: row.entry_item_name
        }
        w.check_point
      end

      w.reset!(entries.keys.size)
      # create entry
      entries.values.each do |entry|
        w.info "JE : #{entry}".inspect.yellow
        j = JournalEntry.create!(entry)
        w.info "JE created: #{j.number} | #{j.printed_on}".inspect.yellow
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
      def find_or_create_account(acc_number, acc_name)
        Maybe(find_account_by_provider(acc_number))
          .recover { find_or_create_account_by_number(acc_number, acc_name) }
          .or_raise
      end

      # @param [String] account_number
      # @return [Account, nil]
      def find_account_by_provider(account_number)
        unwrap_one('account') do
          Account.of_provider_name(self.class.vendor, provider_name)
                 .of_provider_data(:account_number, account_number)
        end
      end

      # @param [String] acc_number
      # @param [String] acc_name
      # @return [Account]
      def find_or_create_account_by_number(acc_number, acc_name)
        normalized = account_normalizer.normalize!(acc_number)

        Maybe(Account.find_by(number: normalized))
          .recover { create_account(acc_number, normalized, acc_name) }
          .or_raise
      end

      # @param [String] acc_number
      # @param [String] acc_name
      # @return [Account]
      def create_account(acc_number, acc_number_normalized, acc_name)
        attrs = {
          name: acc_name,
          number: acc_number_normalized,
          provider: provider_value(account_number: acc_number)
        }
        Account.create!(attrs)
      end

      # @param [String] jou_code
      # @param [String] jou_name
      # @param [Symbol] jou_nature
      # @return [Journal]
      def find_or_create_journal(jou_code, jou_name, jou_nature)
        Maybe(find_journal_by_provider(jou_code))
          .recover { create_journal(jou_code, jou_name, jou_nature) }
          .or_raise
      end

      # @param [String] code
      # @param [String] name
      # @param [Symbol] nature
      # @return [Journal]
      def create_journal(code, name, nature)
        Journal.create!(name: name, code: code, nature: nature, provider: provider_value(journal_code: code))
      end

      # @param [String]
      # @return [Journal, nil]
      def find_journal_by_provider(code)
        unwrap_one('journal') do
          Journal.of_provider_name(self.class.vendor, provider_name)
                 .of_provider_data(:journal_code, code)
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
        :journal_entries
      end

      def parse_file(file)
        rows = ActiveExchanger::CsvReader.new(col_sep: ';').read(file)
        parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

        parser.normalize(rows)
      end
  end
end
