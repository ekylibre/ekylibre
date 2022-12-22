class AddProviderToBankStatementItems < ActiveRecord::Migration[5.2]
  def change
    add_column :bank_statement_items, :provider, :jsonb, default: {}
  end
end
