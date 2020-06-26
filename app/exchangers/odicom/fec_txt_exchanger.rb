module Odicom
  class FecTxtExchanger < ActiveExchanger::Base
    #  0 - A: JournalCode : "2"
    #  1 - B: JournalLib : "BILAN D'OUVERTURE"
    #  2 - C: EcritureNum : "0"
    #  3 - D: EcritureDate : "20190401"
    #  4 - E: CompteNum : "468600000"
    #  5 - F: CompteLib : "Charges à payer"
    #  6 - G: CompAuxNum : ""
    #  7 - H: CompAuxLib : ""
    #  8 - I: PieceRef : "Anouveau"
    #  9 - J: PieceDate : "20190401"
    #  10 - K: EcritureLib : "A nouveau"
    #  11 - L: Debit : "0"
    #  12 - M: Credit : "2981,42"
    #  13 - N: EcritureLet : "A"
    #  14 - O: DateLet : "20190401"
    #  15 - P: ValidDate : "20200428"
    #  16 - Q: MontantDevise
    #  17 - R: Idevise
    NORMALIZATION_CONFIG = [
      { col: 0, name: :journal_code, type: :string },
      { col: 1, name: :journal_lib, type: :string },
      { col: 2, name: :continuous_number, type: :integer },
      { col: 3, name: :printed_on, type: :date },
      { col: 4, name: :account_number, type: :string },
      { col: 5, name: :account_name, type: :string },
      { col: 6, name: :auxiliary_account_number, type: :string },
      { col: 7, name: :auxiliary_account_name, type: :string },
      { col: 8, name: :item_name, type: :string },
      { col: 9, name: :item_printed_on, type: :date },
      { col: 10, name: :entry_item_name, type: :string },
      { col: 11, name: :debit_amount, type: :float },
      { col: 12, name: :credit_amount, type: :float },
      { col: 13, name: :entry_item_letter, type: :string },
      { col: 14, name: :entry_item_lettered_on, type: :string },
      { col: 15, name: :validated_on, type: :date },
      { col: 16, name: :currency_value, type: :float },
      { col: 17, name: :currency_id, type: :string }
    ]

    def check
      # Imports FEC journal entries into journal to make accountancy in CSV format
      # From local software ODICOM (CER 49)
      # filename example : 451104780FEC20200331.TXT
      # separator is '|' and encoding is ISO-8859-15

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

        if (row.debit_amount - row.credit_amount) == 0.0
          w.error "Errors on amount in line : #{line_number} - #{valid}".red
          valid = false
        end

        if row.account_number.blank? || row.printed_on.blank? || row.item_name.blank?
          w.error "Errors on account (#{row.account_number}) or printed_on (#{row.printed_on.to_s}) or item_name (#{row.item_name}) in line : #{line_number} - #{valid}".red
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

      # find or create a unique journal for ODICOM
      journal = find_or_create_journal('ODIC', 'Import ODICOM', 'various')

      entries = {}
      rows.each_with_index do |row, index|
        line_number = index + 2

        # case of negative values
        if row.debit_amount < 0.0
          row.credit_amount = -row.debit_amount
          row.debit_amount = 0.0
        end

        if row.credit_amount < 0.0
          row.debit_amount = -row.credit_amount
          row.credit_amount = 0.0
        end

        raw_number = row.printed_on.strftime("%Y%m%d") + row.journal_code + row.item_name
        number = raw_number.gsub(/(-|_|\s)/, '')

        w.info "--------------------index : #{index} | number : #{line_number}--------------------------"

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
        if row.account_number.start_with?(client_account_radix, supplier_account_radix)
          account = find_or_create_account(row.account_number, row.account_name)
          find_or_create_entities(row.printed_on, account, row.account_number)
          w.info "third account & entity created: #{account.label.inspect.green}"
        else
          account = find_or_create_account(row.account_number, row.account_name)
          w.info "account created: #{account.label.inspect.green}"
        end

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
          Account.of_provider_name(provider_vendor, provider_name)
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

        if acc_number.start_with?(client_account_radix, supplier_account_radix)
          aux_number = acc_number[client_account_radix.length..-1]

          if aux_number.match(/\A0*\z/).present?
            raise StandardError, "Can't create account. Number provided (#{aux_number}) can't be a radical class"
          end

          attrs = attrs.merge(
            centralizing_account_name: acc_number.start_with?(client_account_radix) ? 'clients' : 'suppliers',
            auxiliary_number: aux_number,
            nature: 'auxiliary'
          )
        end

        Account.create!(attrs)
      end

      # @return [String]
      def client_account_radix
        @client_account_radix ||= Preference.value(:client_account_radix).presence || '411'
      end

      # @return [String]
      def supplier_account_radix
        @supplier_account_radix ||= Preference.value(:supplier_account_radix).presence || '401'
      end

      # @param [Date] period_started_on
      # @param [Account] acc
      # @return [Entity]
      def find_or_create_entities(period_started_on, acc, provider_account_number)
        Maybe(find_entities_by_provider(provider_account_number))
          .recover { find_entities_by_account(acc) }
          .recover { [create_entity(period_started_on, acc, provider_account_number)] }
          .or_raise
      end

      # @param [String] provider_account_number
      # @return [Array<Entity>]
      def find_entities_by_provider(provider_account_number)
        Entity.of_provider_name(provider_vendor, provider_name)
              .of_provider_data(:account_number, provider_account_number)
      end

      # @param [Account] account
      # @return [Array<Entity>]
      def find_entities_by_account(account)
        if account.centralizing_account_name == "clients"
          Entity.where(client_account: account).to_a
        elsif account.centralizing_account_name == "suppliers"
          Entity.where(supplier_account: account).to_a
        else
          raise StandardError, "Unreachable code!"
        end
      end

      # @param [Date] period_started_on
      # @param [Account] account
      # @param [String] provider_account_number
      # @return [Entity]
      def create_entity(period_started_on, account, provider_account_number)
        last_name = account.name.mb_chars.capitalize
        attrs = {
          last_name: last_name,
          nature: 'organization',
          first_met_at: period_started_on.to_datetime,
          provider: provider_value(account_number: provider_account_number)
        }
        if account.centralizing_account_name == "clients"
          attrs = {
            **attrs,
            client: true,
            client_account_id: account.id
          }
        elsif account.centralizing_account_name == "suppliers"
          attrs = {
            **attrs,
            supplier: true,
            supplier_account_id: account.id
          }
        else
          raise StandardError, "Unreachable code!"
        end

        Entity.create!(attrs)

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
          Journal.of_provider_name(provider_vendor, provider_name)
                 .of_provider_data(:journal_code, code)
        end
      end

    protected

      def unwrap_one(name, exact: false, &block)
        results = block.call
        size = results.size

        if size > 1
          raise UniqueResultExpectedError, "Expected only one #{name}, got #{size}"
        elsif exact && size == 0
          raise UniqueResultExpectedError, "Expected only one #{name}, got none"
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
        { vendor: provider_vendor, name: provider_name, id: import_resource.id, data: data }
      end

      def provider_name
        :journal_entries
      end

      def provider_vendor
        :odicom
      end

      def parse_file(file)
        rows = ActiveExchanger::CsvReader.new(col_sep: '|').read(file)
        parser = ActiveExchanger::CsvParser.new(NORMALIZATION_CONFIG)

        parser.normalize(rows)
      end

  end
end
