# frozen_string_literal: true

module BordeauxSciencesAgro
  module Istea
    class JournalEntriesExchanger < ActiveExchanger::Base
      category :accountancy
      vendor :bordeaux_sciences_agro

      def check
        # Imports journal entries into journal to make accountancy in CSV format
        # filename example : 17005534_EXPORT_ECRITURES_COMPTABLES.TXT
        # Columns are:
        #  0 - A: journal number : "90"
        #  1 - B: journal code : "STD"
        #  2 - C: printed_on : "01/01/2017"
        #  3 - D: entry code : "STOCK"
        #  4 - E: entry label : "FAçON CULTURALE"
        #  5 - F: ??
        #  6 - G: account number : "34150000"
        #  7 - H: activity code : "3000"
        #  8 - I: ?? : "16"
        #  9 - J: activity name : "ENSILAGE MAIS"
        #  10 - K: quantity : "154.000"
        #  11 - L: quantity_unit : "T"
        #  17 - R: entry item label : "FC 1100 BLE TENDRE"
        #  18 - S: debit : ""
        #  19 - T: credit : "430.50"
        #  21 - V: pretax_amount : "430.50"

        source = File.read(file)
        detection = CharlockHolmes::EncodingDetector.detect(source)
        rows = CSV.read(file, headers: false, encoding: detection[:encoding], col_sep: ';')
        w.count = rows.size

        valid = true

        fy_start = FinancialYear.at(Date.parse(rows.first[2]))
        fy_stop = FinancialYear.at(Date.parse(rows.last[2]))
        unless fy_start && fy_stop
          valid = false
        end

        rows.each_with_index do |row, index|
          line_number = index + 2
          r = parse_row(row)
          # w.check_point

          if r.pretax_base == 0.0 && (r.debit_amount - r.credit_amount) == 0.0
            valid = false
          end

          if r.account_number.blank? || r.printed_on.blank? || r.entry_name.blank?
            valid = false
          end

          w.info "#{line_number} - #{valid}".green
        end
        valid
      end

      def import
        source = File.read(file)
        detection = CharlockHolmes::EncodingDetector.detect(source)
        rows = CSV.read(file, headers: false, encoding: detection[:encoding], col_sep: ';')
        w.count = rows.size

        journal = Journal.find_or_create_by(code: 'ISTE', nature: 'various', name: 'Import ISTEA')

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

          number = r.printed_on.to_s + '_' + r.journal_name + '_' + r.entry_name
          w.info "--------------------index : #{index} | number : #{line_number}--------------------------"

          unless entries[number]
            entries[number] = {
              printed_on: r.printed_on,
              journal: journal,
              number: line_number,
              currency: journal.currency,
              items_attributes: {}
            }
          end

          if r.account_number && r.entry_name
            account = find_or_create_account(r.account_number, r.entry_name)
            if r.account_number.start_with?(client_account_radix, supplier_account_radix)
              find_or_create_entity(r.printed_on, account, r.entry_name)
            end
            w.info "account : #{account.label.inspect.red}"
          end

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

          if acc_number.start_with?(client_account_radix, supplier_account_radix)
            aux_number = acc_number[client_account_radix.length..-1]

            if aux_number.match(/\A0*\z/).present?
              aux_number = acc_name.delete(' ').upcase[0..8]
              # raise StandardError.new("Can't create account. Number provided (#{aux_number}) can't be a radical class")
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
            Entity.of_provider_name(self.class.vendor, provider_name)
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
              raise StandardError.new("Unreachable code!")
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
            raise StandardError.new("Unreachable code!")
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
            Journal.of_provider_name(self.class.vendor, provider_name)
                   .of_provider_data(:journal_code, code)
          end
        end

        def parse_row(row)
          {
            printed_on: Date.parse(row[2].to_s),
            journal_name: row[3].to_s.strip,
            entry_name: row[4].to_s.delete(" ").strip,
            account_number: row[6].to_s.strip,
            account_name: (row[9].blank? ? nil : row[9].to_s.strip),
            entry_item_name: row[17].to_s.strip,
            debit_amount: (row[18].blank? ? 0.0 : row[18].tr(',', '.').to_d),
            credit_amount: (row[19].blank? ? 0.0 : row[19].tr(',', '.').to_d),
            pretax_base: (row[21].blank? ? 0.0 : row[21].tr(',', '.').to_d)
          }.to_struct
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
          { vendor: self.class.vendor, name: provider_name, id: import_resource.id, data: { sender_infos: '', **data } }
        end

        def provider_name
          :journal_entries
        end
    end
  end
end
