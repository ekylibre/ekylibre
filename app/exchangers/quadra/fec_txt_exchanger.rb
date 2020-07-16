module Quadra
  class FecTxtExchanger < ActiveExchanger::Base
    def check
        # Imports FEC journal entries into journal to make accountancy in CSV format
        # From software QUADRA
        # filename example : 451104780FEC20200331.TXT
        # separator is 'tab' and encoding is UTF-8

        source = File.read(file)
        detection = CharlockHolmes::EncodingDetector.detect(source)
        rows = CSV.read(file, headers: true, encoding: detection[:encoding], col_sep: "\t")
        w.count = rows.size

        valid = true

        rows.each_with_index do |row, index|
          line_number = index + 2
          r = parse_row(row)
          # w.check_point

          fy_start = FinancialYear.at(r.printed_on)
          unless fy_start
            w.error "FinancialYear does not exist for #{r.printed_on} in line : #{line_number} - #{valid}".red
            valid = false
          end

          if (r.debit_amount - r.credit_amount) == 0.0
            w.error "Errors on amount in line : #{line_number} - #{valid}".red
            valid = false
          end

          if r.account_number.blank? || r.printed_on.blank? || r.item_name.blank?
            w.error "Errors on account (#{r.account_number}) or printed_on (#{r.printed_on.to_s}) or item_name (#{r.item_name}) in line : #{line_number} - #{valid}".red
            valid = false
          end

          w.info "#{line_number} - #{valid}".green

        end
        w.info "End validation : #{valid}".yellow
        valid
    end

    def import
        source = File.read(file)
        detection = CharlockHolmes::EncodingDetector.detect(source)
        rows = CSV.read(file, headers: true, encoding: detection[:encoding], col_sep: "\t")
        w.count = rows.size

        # find or create a unique journal for ODICOM
        journal = find_or_create_journal('QUADRA', 'Import QUADRA', 'various')

        entries = {}
        rows.each_with_index do |row, index|
          line_number = index + 2
          r = parse_row(row)

          # case of negative values
          if r.debit_amount < 0.0
            r.credit_amount = -r.debit_amount
            r.debit_amount = 0.0
          end

          if r.credit_amount < 0.0
            r.debit_amount = -r.credit_amount
            r.credit_amount = 0.0
          end

          if r.continuous_number
            raw_number = r.printed_on.strftime("%Y%m%d") + r.journal_code + r.continuous_number
          elsif r.item_name
            raw_number = r.printed_on.strftime("%Y%m%d") + r.journal_code + r.item_name
          else
            raise StandardError, "Invalid #{r.continuous_number} or #{r.item_name}"
          end
          number = raw_number.strip.delete("-").delete("_").delete(" ")

          w.info "--------------------index : #{index} | number : #{line_number}--------------------------"

          # create entry attributes
          unless entries[number]
            entries[number] = {
              printed_on: r.printed_on,
              journal: journal,
              number: number,
              currency: journal.currency,
              provider: provider_value,
              items_attributes: {}
            }
          end

          # create account
          if r.account_number.start_with?(client_account_radix, supplier_account_radix)
            if r.auxiliary_account_number && r.auxiliary_account_name

              # get prefix & suffix for creating auxiliary account
              account_prefix = r.account_number[0...client_account_radix.size]
              account_suffix = r.auxiliary_account_number

              account = find_or_create_account((account_prefix + account_suffix), r.auxiliary_account_name)
              find_or_create_entity(r.printed_on, account, (account_prefix + account_suffix))
            else
              account = find_or_create_account(r.account_number, r.account_name)
              find_or_create_entity(r.printed_on, account, r.account_number)
            end
            w.info "third account & entity created: #{account.label.inspect.green}"
          else
            account = find_or_create_account(r.account_number, r.account_name)
            w.info "account created: #{account.label.inspect.green}"
          end

          # create entry item attributes
          id = (entries[number][:items_attributes].keys.max || 0) + 1
          entries[number][:items_attributes][id] = {
            real_debit: r.debit_amount.to_f,
            real_credit: r.credit_amount.to_f,
            account: account,
            name: r.entry_item_name
          }
          w.check_point
        end

        w.reset!(entries.keys.size)
        # create entry
        entries.values.each do |entry|
          w.info "JE : #{entry[:number]}".inspect.yellow
          j = JournalEntry.create!(entry)
          w.info "JE created: #{j.number} | #{j.printed_on}".inspect.yellow
          w.check_point
        end
    end

    private

        #  0 - A: JournalCode : "AN"
        #  1 - B: JournalLib : "A NOUVEAUX"
        #  2 - C: EcritureNum : "AN000001"
        #  3 - D: EcritureDate : "20180801"
        #  4 - E: CompteNum : "41100000"
        #  5 - F: CompteLib : "COLLECTIF CLIENTS"
        #  6 - G: CompAuxNum : "01ACSO00"
        #  7 - H: CompAuxLib : "ACSO"
        #  8 - I: PieceRef : "x"
        #  9 - J: PieceDate : "20170801"
        #  10 - K: EcritureLib : "Report exercice précédent"
        #  11 - L: Debit : "777,18"
        #  12 - M: Credit : "0"
        #  13 - N: EcritureLet : "AA"
        #  14 - O: DateLet : ""
        #  15 - P: ValidDate : "20191114"
        #  16 - Q: MontantDevise : ""
        #  17 - R: Idevise : ""

        def parse_row(row)
          {
            journal_code: row[0].to_s.strip,
            journal_lib: row[1].to_s.strip,
            continuous_number: ((row[2].blank? || row[2].to_s == 0) ? nil : row[2].to_s),
            printed_on: Date.parse(row[3].to_s),
            account_number: row[4].to_s.strip,
            account_name: (row[5].blank? ? nil : row[5].to_s.strip),
            auxiliary_account_number: (row[6].blank? ? nil : row[6].to_s.strip),
            auxiliary_account_name: (row[7].blank? ? nil : row[7].to_s.strip),
            item_name: row[8].to_s.strip,
            item_printed_on: Date.parse(row[9].to_s),
            entry_item_name: row[10].to_s.strip,
            debit_amount: (row[11].blank? ? 0.0 : row[11].tr(',', '.').to_d),
            credit_amount: (row[12].blank? ? 0.0 : row[12].tr(',', '.').to_d),
            entry_item_letter: (row[13].blank? ? nil : row[13].to_s.strip),
            entry_item_lettered_on: (row[14].blank? ? nil : Date.parse(row[14].to_s)),
            validated_on: (row[15].blank? ? nil : Date.parse(row[15].to_s)),
            currency_value: (row[16].blank? ? nil : row[16].tr(',', '.').to_d),
            currency_id: (row[17].blank? ? nil : row[17].to_s.strip)
          }.to_struct
        end

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
          @client_account_radix ||= (Preference.value(:client_account_radix).presence || '411')
        end

        # @return [String]
        def supplier_account_radix
          @supplier_account_radix ||= (Preference.value(:supplier_account_radix).presence || '401')
        end

        # @param [Date] period_started_on
        # @param [Account] acc
        # @return [Entity]
        def find_or_create_entity(period_started_on, acc, provider_account_number)
          entity = Maybe(find_entity_by_provider(provider_account_number))
            .recover { find_entity_by_account(acc) }
            .recover { create_entity(period_started_on, acc, provider_account_number) }
            .or_raise

          if entity.first_met_at.nil? || (period_started_on && period_started_on < entity.first_met_at.to_date)
            entity.update!(first_met_at: period_started_on.to_datetime)
          end

          entity
        end

        # @param [String] sage_account_number
        # @return [Entity, nil]
        def find_entity_by_provider(provider_account_number)
          unwrap_one('entity') do
            Entity.of_provider_name(provider_vendor, provider_name)
                  .of_provider_data(:account_number, provider_account_number)
          end
        end

        # @param [Account] account
        # @return [Entity, nil]
        def find_entity_by_account(account)
          unwrap_one('entity') do
            if account.centralizing_account_name == "clients"
              Entity.where(client_account: account)
            elsif account.centralizing_account_name == "suppliers"
              Entity.where(supplier_account: account)
            else
              raise StandardError, "Unreachable code!"
            end
          end
        end

        # @param [Date] period_started_on
        # @param [Account] account
        # @param [String] sage_account_number
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
        { vendor: provider_vendor, name: provider_name, id: import_resource.id, data: { sender_infos: '', **data } }
      end

      def provider_name
        :journal_entries
      end

      def provider_vendor
        :quadra
      end

  end
end
