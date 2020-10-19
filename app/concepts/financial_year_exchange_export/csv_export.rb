class FinancialYearExchangeExport
  class CsvExport
    def initialize(exchange)
      @exchange = exchange
    end

    def export
      filename = 'journal-entries-export.csv'
      tempfile = Tempfile.new(filename)
      write_csv tempfile.path
      yield tempfile, filename
    ensure
      tempfile.close!
    end

    private

      attr_reader :exchange

      def write_csv(filepath)
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

        CSV.open(filepath, 'w+') do |csv|
          csv << headers
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
      end

      def headers
        [
          'Jour',
          'Numéro de compte',
          'Journal',
          'Tiers',
          'Numéro de pièce',
          'Libellé écriture',
          'Débit',
          'Crédit',
          'Lettrage'
        ]
      end
  end
end
