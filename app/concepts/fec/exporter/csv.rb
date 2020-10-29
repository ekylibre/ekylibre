module FEC
  module Exporter
    class CSV < FEC::Exporter::Base
      private

      def build(journals)
        columns = {
          'JournalCode' => 'j.code',
          'JournalLib' => 'j.name',
          'EcritureNum' => 'je.continuous_number',
          'EcritureDate' => "TO_CHAR(je.printed_on::DATE, 'YYYYMMDD')",
          'CompteNum' => "greatest(a.number::VARCHAR, rpad(a.number::VARCHAR, 3, '0'))",
          'CompteLib' => 'a.name',
          'CompAuxNum' => "NULL",
          'CompAuxLib' => "NULL",
          'PieceRef' => 'je.number',
          'PieceDate' => "TO_CHAR(je.printed_on::DATE, 'YYYYMMDD')",
          'EcritureLib' => 'jei.name',
          'Debit' => "replace((ROUND(jei.debit, 2))::text, '.', ',')",
          'Credit' => "replace((ROUND(jei.credit, 2))::text, '.', ',')",
          'EcritureLet' => "jei.letter",
          'DateLet' => "NULL",
          'ValidDate' => "TO_CHAR(je.validated_at::DATE, 'YYYYMMDD')",
          'Montantdevise' => "NULL",
          'Idevise' => "NULL"
        }

        if %w[ba_ir_cash_accountancy bnc_ir_cash_accountancy].include? fiscal_position
          columns.merge!({
            'DateRglt' => "TO_CHAR(payments.paid_at, 'YYYYMMDD')",
            'ModeRglt' => "payments.mode_name",
            'NatOp' => "NULL"
          })
        end

        if fiscal_position == 'bnc_ir_cash_accountancy'
          columns.merge!({
            'IdClient' => "t.number"
          })
        end

        select = columns.map { |k, v| "#{v} AS \"#{k}\"" }.join(', ')
        query = <<-SQL.strip_heredoc
          SELECT #{select}
          FROM journal_entry_items AS jei
            JOIN journal_entries AS je
              ON (jei.entry_id = je.id
                  AND je.state <> 'draft'
                  AND je.printed_on BETWEEN '#{@started_on}' AND '#{@stopped_on}'
                  )
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
        SQL

        if %w[ba_ir_cash_accountancy bnc_ir_cash_accountancy].include? fiscal_position
          query += <<-SQL.strip_heredoc
            LEFT JOIN (
              (SELECT 'IncomingPayment' AS type, incoming_payments.id, paid_at, incoming_payment_modes.name AS mode_name
                FROM incoming_payments
                JOIN incoming_payment_modes ON incoming_payment_modes.id = incoming_payments.mode_id
                ORDER BY "paid_at" ASC)
              UNION ALL
              (SELECT 'OutgoingPayment' AS type, outgoing_payments.id, paid_at, outgoing_payment_modes.name AS mode_name
                FROM outgoing_payments
                JOIN outgoing_payment_modes ON outgoing_payment_modes.id = outgoing_payments.mode_id
                ORDER BY "paid_at" ASC)
            ) AS payments ON (payments.id = je.resource_id AND payments.type = je.resource_type)
          SQL
        end

        query += <<-SQL.strip_heredoc
          WHERE jei.journal_id IN (#{journals.pluck(:id).join(', ')}) AND jei.balance <> 0.0
          AND j.nature <> 'closure' AND a.number ~ '\\\A[1-7]'
          ORDER BY je.validated_at::DATE, je.continuous_number, je.created_at
        SQL

        ::CSV.generate col_sep: '|', encoding: 'ISO-8859-15' do |csv|
          csv << columns.keys
          ActiveRecord::Base.connection.select_rows(query).each do |row|

            row[1] = CGI::escapeHTML(row[1].dump[1..-2])
            row[5] = CGI::escapeHTML(row[5].dump[1..-2])
            row[10] = CGI::escapeHTML(row[10].dump[1..-2])

            csv << row
          end
        end
      end
    end
  end
end
