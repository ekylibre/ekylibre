class CreateDebtTransfers < ActiveRecord::Migration
  def change
    create_table :debt_transfers do |t|
      t.integer :sale_affair_id, index: true, null: false
      t.integer :purchase_affair_id, index: true, null: false
      t.decimal :amount
      t.string :currency, null: false
      t.integer :sale_regularization_journal_entry_id
      t.integer :purchase_regularization_journal_entry_id
      t.datetime :accounted_at
      t.stamps
    end
  end
end
