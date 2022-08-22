# frozen_string_literal: true

module FinancialYearExchanges
  class CsvExport

    LABEL_REGEXP= "[^! »#$%&’()*+,-.\/ :;<>= ?@[\\]^_{|}0-9A-Za-z]"
    NAME_REGEXP = "[^! »#$%&’()*+,-.\/ :;<>= ?@[\\]^_{|}0-9A-Za-z]"

    def generate_file(exchange, transmit_isacompta_analytic_codes)
      if exchange.format == 'isacompta'
        yield generate_isacompta(exchange, transmit_isacompta_analytic_codes)
      else
        yield generate_ekyagri(exchange)
      end
    end

    HEADERS = %w[jour
                 numero_compte
                 journal
                 tiers
                 numero_piece
                 libelle_ecriture
                 debit
                 credit
                 lettrage
                 code_tva].freeze

    def generate_ekyagri(exchange)
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
              journal_entry_items.letter AS letter,
              CASE
                WHEN journal_entry_items.tax_id IS NOT NULL AND journal_entry_items.account_id = taxes.deduction_account_id THEN taxes.deduction_isacompta_code
                WHEN journal_entry_items.tax_id IS NOT NULL AND journal_entry_items.account_id = taxes.collect_account_id THEN taxes.collect_isacompta_code
                WHEN journal_entry_items.tax_id IS NOT NULL AND journal_entry_items.account_id = taxes.fixed_asset_deduction_account_id THEN taxes.fixed_asset_deduction_isacompta_code
                WHEN journal_entry_items.tax_id IS NOT NULL AND journal_entry_items.account_id = taxes.fixed_asset_collect_account_id THEN taxes.fixed_asset_collect_isacompta_code
                ELSE NULL
              END AS vat_code
          FROM journal_entries
          JOIN journal_entry_items ON (journal_entries.id = journal_entry_items.entry_id)
          JOIN accounts ON (journal_entry_items.account_id = accounts.id)
          LEFT JOIN entities ON (
              accounts.id = entities.supplier_account_id OR
              accounts.id = entities.client_account_id OR
              accounts.id = entities.employee_account_id
          )
          LEFT JOIN taxes ON (
              journal_entry_items.tax_id = taxes.id
          )
          JOIN journals ON (journal_entries.journal_id = journals.id)
          WHERE journal_entries.financial_year_exchange_id = #{exchange.id}
          ORDER BY journal_entries.printed_on, journal_entries.id, journal_entry_items.id
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
              row['letter'],
              row['vat_code']
            ]
          end
        end
        tempfile.close
        tempfile
      end
    end

    ISACOMPTA_HEADERS = %w[id
                           jour
                           numero_compte
                           journal
                           libelle_journal
                           type_compte
                           numero_piece
                           libelle_ecriture
                           debit
                           credit
                           lettrage
                           date_echeance
                           code_tva
                           sequence_analytique].freeze

    def generate_isacompta(exchange, transmit_isacompta_analytic_codes)
      if transmit_isacompta_analytic_codes
        Tempfile.open do |tempfile|
          query = <<~SQL
            SELECT
                journal_entry_items.id AS id,
                journal_entries.printed_on AS printed_on,
                accounts.number AS account_number,
                journals.isacompta_code AS journal_code,
                journals.isacompta_label AS journal_label,
                accounts.nature AS account_type,
                journal_entries.number AS journal_entry_number,
                journal_entry_items.name AS name,
                journal_entry_items.absolute_debit AS debit,
                journal_entry_items.absolute_credit AS credit,
                journal_entry_items.isacompta_letter AS letter,
                outgoing_payments.to_bank_at AS to_paid_at,
                CASE
                  WHEN journal_entry_items.tax_id IS NOT NULL AND journal_entry_items.account_id = taxes.deduction_account_id THEN taxes.deduction_isacompta_code
                  WHEN journal_entry_items.tax_id IS NOT NULL AND journal_entry_items.account_id = taxes.collect_account_id THEN taxes.collect_isacompta_code
                  WHEN journal_entry_items.tax_id IS NOT NULL AND journal_entry_items.account_id = taxes.fixed_asset_deduction_account_id THEN taxes.fixed_asset_deduction_isacompta_code
                  WHEN journal_entry_items.tax_id IS NOT NULL AND journal_entry_items.account_id = taxes.fixed_asset_collect_account_id THEN taxes.fixed_asset_collect_isacompta_code
                  ELSE NULL
                END AS vat_code,
                activities.isacompta_analytic_code AS activity_analytic_code,
                project_budgets.isacompta_analytic_code AS project_budget_analytic_code,
                teams.isacompta_analytic_code AS team_analytic_code,
                equipments.isacompta_analytic_code AS equipment_analytic_code

            FROM journal_entries
            JOIN journal_entry_items ON (journal_entries.id = journal_entry_items.entry_id)
            JOIN accounts ON (journal_entry_items.account_id = accounts.id)
            LEFT JOIN entities ON (
                accounts.id = entities.supplier_account_id OR
                accounts.id = entities.client_account_id OR
                accounts.id = entities.employee_account_id
            )
            LEFT JOIN taxes ON (
                journal_entry_items.tax_id = taxes.id
            )
            LEFT JOIN activity_budgets ON
              journal_entry_items.activity_budget_id = activity_budgets.id
            LEFT JOIN activities ON
              activities.id = activity_budgets.activity_id
            LEFT JOIN project_budgets ON
              journal_entry_items.project_budget_id = project_budgets.id
            LEFT JOIN teams ON
              teams.id = journal_entry_items.team_id
            LEFT JOIN products AS equipments ON
              equipments.id = journal_entry_items.equipment_id
            LEFT JOIN outgoing_payments ON
              outgoing_payments.journal_entry_id = journal_entries.id
            JOIN journals ON (journal_entries.journal_id = journals.id)
            WHERE journal_entries.financial_year_exchange_id = #{exchange.id}
            ORDER BY journal_entries.printed_on, journal_entries.id
          SQL

          CSV.open(tempfile, 'w+') do |csv|
            csv << ISACOMPTA_HEADERS
            ApplicationRecord.connection.execute(query).each do |row|
              csv << [
                row['id'],
                Date.parse(row['printed_on']).strftime('%d%m%Y'),
                row['account_number'],
                row['journal_code'],
                row['journal_label']&.[](0..29)&.gsub(/LABEL_REGEXP/, ''),
                row['account_type']&.[](0..1),
                row['journal_entry_number'],
                row['name']&.[](0..29)&.gsub(/NAME_REGEXP/, ''),
                row['debit'],
                row['credit'],
                row['letter'],
                row['to_paid_at'],
                row['vat_code'],
                AnalyticSequence.first.segments.map do |segment|
                  row[segment.name.singularize + '_analytic_code']
                end.join('')
              ]
            end
          end
          tempfile.close
          tempfile
        end
      else
        Tempfile.open do |tempfile|
          query = <<~SQL
            SELECT
                journal_entry_items.id AS id,
                journal_entries.printed_on AS printed_on,
                accounts.number AS account_number,
                journals.isacompta_code AS journal_code,
                journals.isacompta_label AS journal_label,
                accounts.nature AS account_type,
                journal_entries.number AS journal_entry_number,
                journal_entry_items.name AS name,
                journal_entry_items.absolute_debit AS debit,
                journal_entry_items.absolute_credit AS credit,
                journal_entry_items.isacompta_letter AS letter,
                outgoing_payments.to_bank_at AS to_paid_at,
                CASE
                  WHEN journal_entry_items.tax_id IS NOT NULL AND journal_entry_items.account_id = taxes.deduction_account_id THEN taxes.deduction_isacompta_code
                  WHEN journal_entry_items.tax_id IS NOT NULL AND journal_entry_items.account_id = taxes.collect_account_id THEN taxes.collect_isacompta_code
                  WHEN journal_entry_items.tax_id IS NOT NULL AND journal_entry_items.account_id = taxes.fixed_asset_deduction_account_id THEN taxes.fixed_asset_deduction_isacompta_code
                  WHEN journal_entry_items.tax_id IS NOT NULL AND journal_entry_items.account_id = taxes.fixed_asset_collect_account_id THEN taxes.fixed_asset_collect_isacompta_code
                  ELSE NULL
                END AS vat_code

            FROM journal_entries
            JOIN journal_entry_items ON (journal_entries.id = journal_entry_items.entry_id)
            JOIN accounts ON (journal_entry_items.account_id = accounts.id)
            LEFT JOIN entities ON (
                accounts.id = entities.supplier_account_id OR
                accounts.id = entities.client_account_id OR
                accounts.id = entities.employee_account_id
            )
            LEFT JOIN taxes ON (
                journal_entry_items.tax_id = taxes.id
            )
            LEFT JOIN outgoing_payments ON
              outgoing_payments.journal_entry_id = journal_entries.id
            JOIN journals ON (journal_entries.journal_id = journals.id)
            WHERE journal_entries.financial_year_exchange_id = #{exchange.id}
            ORDER BY journal_entries.printed_on, journal_entries.id
          SQL

          CSV.open(tempfile, 'w+') do |csv|
            csv << ISACOMPTA_HEADERS
            ApplicationRecord.connection.execute(query).each do |row|
              csv << [
                row['id'],
                Date.parse(row['printed_on']).strftime('%d%m%Y'),
                row['account_number'],
                row['journal_code'],
                row['journal_label']&.[](0..29)&.gsub(/LABEL_REGEXP/, ''),
                row['account_type']&.[](0..1),
                row['journal_entry_number'],
                row['name']&.[](0..29)&.gsub(/NAME_REGEXP/, ''),
                row['debit'],
                row['credit'],
                row['letter'],
                (row['to_paid_at'].present? ? Date.parse(row['to_paid_at']).strftime('%d%m%Y') : nil),
                row['vat_code']
              ]
            end
          end
          tempfile.close
          tempfile
        end
      end
    end

    def filename(_exchange)
      'journal-entries-export.csv'
    end
  end
end
