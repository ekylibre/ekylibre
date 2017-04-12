# coding: utf-8

module Legrain
  module Epicea
    class JournalsExchanger < ActiveExchanger::Base
      JOURNAL_NATURES = {
        AC: :purchases,
        B: :bank,
        OD: :various,
        VT: :sales
      }.with_indifferent_access

      def import
        rows = CSV.read(file, headers: true, encoding: 'cp1252', col_sep: ';', skip_blanks: true, quote_char: '🐧')

        Preference.set!(:currency, :EUR) unless Preference.find_by(name: :currency)

        entries = {}
        w.reset!(rows.count, :yellow)
        rows.each_with_index do |row, _index|
          number = row[1].to_s.strip
          unless entries[number]
            journal = Journal.create_with(
              name: "Journal #{row[0]}",
              nature: JOURNAL_NATURES[row[0].sub(/[0-9]/, '')]
            ).find_or_create_by!(
              code: row[0],
              currency: 'EUR'
            )
            entries[number] = {
              printed_on: Date.parse(row[2]),
              journal: journal,
              number: number,
              currency: journal.currency,
              items_attributes: {}
            }
          end
          account_number = row[3].to_s.upcase
          account = Account.find_or_create_by_number(account_number, name: account_number)
          id = (entries[number][:items_attributes].keys.max || 0) + 1
          entries[number][:items_attributes][id] = {
            real_debit: row[6].to_f,
            real_credit: row[7].to_f,
            account: account,
            name: row[5]
          }
        end

        started_on = entries.values.map { |v| v[:printed_on] }.uniq.sort.first
        FinancialYear.create!(started_on: started_on.beginning_of_month) unless FinancialYear.on(started_on)

        w.reset!(entries.keys.size)
        entries.values.each do |entry|
          JournalEntry.create!(entry)
          w.check_point
        end
      end
    end
  end
end
