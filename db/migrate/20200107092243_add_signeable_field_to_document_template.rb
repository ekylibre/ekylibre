class AddSigneableFieldToDocumentTemplate < ActiveRecord::Migration
  def change
    add_column :document_templates, :signed, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE document_templates SET signed = 't' WHERE nature IN ('sales_invoice', 'trial_balance', 'general_ledger', 'journal_ledger')
        SQL
      end
    end
  end
end
