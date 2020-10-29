module BordeauxSciencesAgro
  module Istea
    class JournalEntriesExchanger < ActiveExchanger::Base
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

          puts "#{line_number} - #{valid}".green

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
            if r.account_number == '41100000' || r.account_number == '40100000'
              if r.entry_name.length < 5
                r.entry_name.delete(" ").ljust(5, "Z")
              end
              r.account_number = r.account_number[0..2] + r.entry_name
            end
            if r.account_name
              acc_name = r.account_name
            else
              acc_name = r.entry_name
            end
            account = Account.find_or_create_by_number(r.account_number, name: acc_name)
            w.info "account : #{account.label.inspect.red}"
          end

          id = (entries[number][:items_attributes].keys.max || 0) + 1
          entries[number][:items_attributes][id] = {
            real_debit: r.debit_amount.to_f,
            real_credit: r.credit_amount.to_f,
            account: account,
            name: r.entry_item_name
          }

          # Adds a real entity with known information if account number like 401 or 411
          if account.number =~ /^4(0|1)\d/
            last_name = r.entry_name.mb_chars.capitalize
            modified = false
            entity ||= Entity.where('last_name ILIKE ?', last_name).first || Entity.create!(last_name: last_name, nature: 'organization', first_met_at: r.printed_on)
            if entity.first_met_at && r.printed_on && r.printed_on < entity.first_met_at
              entity.first_met_at = r.printed_on
              modified = true
            end
            if account.number =~ /^401/
              entity.supplier = true
              entity.supplier_account_id = account.id
              modified = true
            end
            if account.number =~ /^411/
              entity.client = true
              entity.client_account_id = account.id
              modified = true
            end
            entity.save if modified
          end
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

    end
  end
end
