# coding: utf-8
module FermesLarrere
  # Imports journal entries into journal to make payment in CSV format
  # Columns are:
  #  0 - A: entity account number
  #  1 - B: account number
  #  2 - C: account name
  #  3 - D: journal code
  #  4 - E: entry number
  #  5 - F: date
  #  6 - G: account exchange number
  #  7 - H: entry title
  #  8 - I: entry description
  #  9 - J: debit amount
  #  10 - K: credit amount
  #  11 - L: balance amount
  #  12 - M: entity external code

  class VariousJournalEntriesExchanger < ActiveExchanger::Base
    def import
      # get journal
      journal = Journal.find_by(code: 'ISA')
      unless journal
        journal = Journal.create!(
          code: 'ISA',
          name: 'Journal de cloture',
          currency: 'EUR',
          nature: :various
        )
      end

      # set exchange account
      exchange_account_number = '471'
      exchange_account_name = 'Attente reprise ecriture'
      exchange_account = Account.find_or_create_by_number(exchange_account_number, name: exchange_account_name)

      # set end date
      date = '2016-09-30'
      end_date = Date.parse(date)

      Preference.set!(:currency, :EUR) unless Preference.find_by(name: :currency)

      rows = CSV.read(file, headers: true, encoding: 'cp1252', col_sep: ';', skip_blanks: true, quote_char: '🐧')

      w.count = rows.count

      rows.each_with_index do |row, _index|
        entry = {}

        entry = {
          printed_on: end_date, # Date.parse(row[5])
          journal: journal,
          # number: row[3].to_s.strip.gsub(/\W/, "") + (index + 1).to_s,
          currency: journal.currency,
          items_attributes: {}
        }

        entity_account_number = (row[0].nil? ? nil : row[0].to_s.strip.upcase)
        entity_account = Account.find_by(number: entity_account_number) if entity_account_number

        account_number = row[1].to_s.strip.upcase
        account_name = (row[2].nil? ? row[2].to_s.strip : account_number)
        account = Account.find_or_create_by_number(account_number, name: account_name)

        # find or create client if row 0 blank and row 12 not empty
        unless entity_account_number
          if row[12]
            entity = Entity.find_by(client_account_id: account.id) if account
            entity ||= Entity.where('codes ->> ? = ?', FermesLarrere::EUROFLOW_KEY, row[12].to_s).first
            unless entity
              entity = Entity.new
              entity.nature = :organization
              entity.active = true
              entity.client = true
              entity.last_name = row[12].to_s
              entity.codes = { FermesLarrere::EUROFLOW_KEY => row[12].to_s }
              entity.save!
              w.info 'New entity'.green
            end
          end
        end

        description = row[8].to_s.strip + ' | ' + Date.parse(row[5]).to_s + ' | ' + account_number

        # create journal entry item
        id = 0
        entry[:items_attributes][id] = {
          real_debit: row[9].tr(',', '.').to_d,
          real_credit: row[10].tr(',', '.').to_d,
          account: (entity_account ? entity_account : account),
          name: description
        }

        # create exchange journal entry item
        id = 1
        entry[:items_attributes][id] = {
          real_debit: (row[10].tr(',', '.').to_d > 0.0 ? row[10].tr(',', '.').to_d : 0.0),
          real_credit: (row[9].tr(',', '.').to_d ? row[9].tr(',', '.').to_d : 0.0),
          account: exchange_account,
          name: description
        }

        # create entry
        JournalEntry.create!(entry)

        w.check_point
      end
    end
  end
end
