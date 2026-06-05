class AddLegalRetentionToDocuments < ActiveRecord::Migration[5.2]
  def change
    add_column :documents, :legal_retention_until, :date
    add_index :documents, :legal_retention_until
  end
end
