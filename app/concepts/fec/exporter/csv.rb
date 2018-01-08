module FEC
  module Exporter
    class CSV < FEC::Exporter::Base
      private

      def build(journals)
        columns = {
          'JournalCode' => 'j.code',
          'JournalLib' => 'j.name',
          'EcritureNum' => 'je.number',
          'EcritureDate' => 'je.printed_on',
          'CompteNum' => 'a.number',
          'CompteLib' => 'a.name',
          'CompAuxNum' => "''",
          'CompAuxLib' => "''",
          'PieceRef' => 'p.number',
          'PieceDate' => 'p.created_at::DATE',
          'EcritureLib' => 'jei.name',
          'Debit' => 'ROUND(jei.debit, 2)',
          'Credit' => 'ROUND(jei.credit, 2)',
          'EcritureLet' => "''",
          'DateLet' => "''",
          'ValidDate' => 'je.printed_on',
          'Montantdevise' => "''",
          'Idevise' => "''",
          'TiersNum' => 't.number',
          'TiersLib' => 't.full_name'
        }
        select = columns.map { |k, v| "#{v} AS \"#{k}\"" }.join(', ')
        query = <<-SQL.strip_heredoc
          SELECT #{select}
          FROM journal_entry_items AS jei
            JOIN journal_entries AS je ON (jei.entry_id = je.id)
            JOIN journals AS j ON (je.journal_id = j.id)
            JOIN accounts AS a ON (jei.account_id = a.id)
            LEFT JOIN (
              SELECT 'Sale' AS type, id, number, created_at, client_id AS third_id
                FROM sales
              UNION ALL
              SELECT 'Purchase' AS type, id, number, created_at, supplier_id AS third_id
                FROM purchases
              UNION ALL
              SELECT 'IncomingPayment' AS type, id, number, created_at, payer_id AS third_id
                FROM incoming_payments
              UNION ALL
              SELECT 'OutgoingPayment' AS type, id, number, created_at, payee_id AS third_id
                FROM outgoing_payments
              ) AS p ON (p.id = je.resource_id AND p.type = je.resource_type)
            LEFT JOIN entities AS t ON (t.id = p.third_id)
          WHERE jei.journal_id IN (#{journals.pluck(:id).join(', ')})
SQL
        ::CSV.generate do |csv|
          csv << columns.keys
          ActiveRecord::Base.connection.select_rows(query).each do |row|
            csv << row
          end
        end
      end
    end
  end
end
