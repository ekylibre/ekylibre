module Isagri
  module Isacompta
    class JournalEntriesExchanger < ActiveExchanger::Base

      # Imports journal entries into journal to make payment in CSV format
      # Columns are:
      #  0 - A: account number
      #  1 - B: account name
      #  2 - C: journal code
      #  3 - D: entry number
      #  4 - E: date
      #  5 - F: account exchange number
      #  6 - G: entry title
      #  7 - H: entry description
      #  8 - I: debit amount
      #  9 - J: credit amount
      #  10 - K: balance amount
      #  11 - L: vat code
      #  12 - M: letter
      #  13 - N: pointing
      #  14 - O: number ?
      #  15 - P: quantity
      #  16 - Q: quantity_unity

      def import
        source = File.read(file)
        detection = CharlockHolmes::EncodingDetector.detect(source)
        rows = CSV.read(file, headers: true, col_sep: ';', encoding: detection[:encoding])
        w.count = rows.size

        currency_preference = Preference[:currency]

        Preference.set!(:currency, :EUR) unless Preference.find_by(name: :currency)

        # status to map
        quantity_unit_transcode = {
          'kg' => :kilogram,
          'L' => :liter,
          'M3' => :cubic_meter,
          'T' => :ton,
          'U' => :unity
        }

        entries = {}

        w.reset!(rows.count, :yellow)

        rows.each_with_index do |row, index|


          r = {
            account_number: row[0].blank? ? nil : row[0].to_s,
            account_name: row[1].blank? ? nil : row[1].to_s,
            journal_code: row[2].blank? ? nil : row[2].to_s.strip,
            entry_number: row[3].blank? ? nil : row[3].to_s.strip,
            printed_on: row[4].blank? ? nil : Date.strptime(row[4].to_s, '%d/%m/%Y'),
            account_exchange_number: row[5].blank? ? nil : row[5].to_s,
            entry_title: row[6].blank? ? nil : row[6].to_s,
            entry_description: row[7].blank? ? nil : row[7].to_s,
            debit_amount: row[8].blank? ? nil : row[8].tr(',', '.').to_d,
            credit_amount: row[9].blank? ? nil : row[9].tr(',', '.').to_d,
            balance_amount: row[10].blank? ? nil : row[10].tr(',', '.').to_d,
            vat_code: row[11].blank? ? nil : row[11].to_s,
            letter: row[12].blank? ? nil : row[12].to_s,
            pointing: row[13].blank? ? nil : row[13].to_s,
            quantity: row[15].blank? ? nil : row[15].tr(',', '.').to_d,
            quantity_unit: row[16].blank? ? nil : row[16].to_s
          }.to_struct

          # case of negative values
          if r.debit_amount < 0.0
            r.credit_amount = - r.debit_amount
            r.debit_amount = 0.0
          end

          if r.credit_amount < 0.0
            r.debit_amount = - r.credit_amount
            r.credit_amount = 0.0
          end


          number = r.entry_number + '_' + r.journal_code


          unless entries[number]
            journal = Journal.find_by(code: r.journal_code)
            unless journal
              journal = Journal.create!(
                code: r.journal_code,
                name: r.journal_code,
                currency: 'EUR',
                nature: :various
              )
            end
            entries[number] = {
              printed_on: r.printed_on,
              journal: journal,
              number: r.entry_number,
              currency: journal.currency,
              items_attributes: {}
            }
          end

          # get or create asset account
          if r.account_number && r.account_name
            account = Account.find_or_create_by_number(r.account_number, name: r.account_name)
            w.info "account : #{account.label.inspect.red}"
          end

          name = r.entry_description
          name ||= r.entry_title

          id = (entries[number][:items_attributes].keys.max || 0) + 1
          entries[number][:items_attributes][id] = {
            real_debit: r.debit_amount.to_f,
            real_credit: r.credit_amount.to_f,
            account: account,
            name: name
          }

          w.check_point
        end

        w.reset!(entries.keys.size)
        entries.values.each do |entry|
          j = JournalEntry.create!(entry)
          puts "JE : #{j.number} | #{j.printed_on}".inspect.yellow
          w.check_point
        end

      end
    end
  end
end
