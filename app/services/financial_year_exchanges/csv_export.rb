# frozen_string_literal: true

module FinancialYearExchanges
  class CsvExport

    HEADERS = %w[jour
                 numéro\ de\ compte
                 journal
                 tiers
                 numéro\ de\ pièce
                 libellé\ écriture
                 débit
                 crédit
                 lettrage].freeze

    def generate_file(exchange)
      Tempfile.open do |tempfile|
        query = <<~SQL
          SELECT
              journal_entries.printed_on AS printed_on,
              accounts.number AS account_number,
              journals.code AS journal_code,
              entities.full_name AS full_name,
              journal_entries.number AS journal_entry_number,
              journal_entry_items.name AS name,
              journal_entry_items.absolute_debit AS debit,
              journal_entry_items.absolute_credit AS credit,
              journal_entry_items.letter AS letter

          FROM journal_entries
          JOIN journal_entry_items ON (journal_entries.id = journal_entry_items.entry_id)
          JOIN accounts ON (journal_entry_items.account_id = accounts.id)
          LEFT JOIN entities ON (
              accounts.id = entities.supplier_account_id OR
              accounts.id = entities.client_account_id OR
              accounts.id = entities.employee_account_id
          )
          JOIN journals ON (journal_entries.journal_id = journals.id)
          WHERE journal_entries.financial_year_exchange_id = #{exchange.id}
          ORDER BY journal_entries.printed_on, journal_entries.id
        SQL

        CSV.open(tempfile, 'w+') do |csv|
          csv << HEADERS
          ApplicationRecord.connection.execute(query).each do |row|
            csv << [
              row['printed_on'],
              row['account_number'],
              row['journal_code'],
              row['full_name'],
              row['journal_entry_number'],
              row['name'],
              row['debit'],
              row['credit'],
              row['letter']
            ]
          end
        end
        tempfile.close
        yield tempfile
      end
    end

    def filename(_exchange)
      'journal-entries-export.csv'
    end
  end
end
