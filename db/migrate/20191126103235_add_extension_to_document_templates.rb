class AddExtensionToDocumentTemplates < ActiveRecord::Migration
  def change
    add_column :document_templates, :file_extension, :string, default: :xml

    sql = <<-SQL
      UPDATE document_templates
      SET "file_extension" = '?'
      WHERE managed = 't'
      AND nature IN (
                      'account_statement_non_letter',
                      'account_statement',
                      'balance_sheet',
                      'by_account_fixed_asset_registry',
                      'check_letter_outgoing_payment_list_banque_populaire_development',
                      'check_letter_outgoing_payment_list_development',
                      'check_letter_outgoing_payment_list',
                      'fixed_asset_registry',
                      'gain_and_loss_fixed_asset_registry',
                      'general_journal',
                      'general_ledger',
                      'income_statement',
                      'journal_ledger',
                      'land_parcel_register',
                      'pending_vat_register',
                      'purchase_order',
                      'sales_estimate',
                      'sales_invoice',
                      'sales_order',
                      'shipping_note',
                      'short_balance_sheet',
                      'standard_outgoing_payment_list',
                      'trial_balance',
                      'vat_register',
                      'worker_register'
                      )
    SQL

    reversible do |d|
      d.up do
        execute sql, 'odt'
      end
    end
  end
end
