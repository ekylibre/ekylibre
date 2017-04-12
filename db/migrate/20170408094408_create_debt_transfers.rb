class CreateDebtTransfers < ActiveRecord::Migration
  def change
    create_table :debt_transfers do |t|
      t.integer :affair_id, index: true, null: false
      t.integer :debt_transfer_affair_id, index: true, null: false
      t.decimal :amount, precision: 19, scale: 4, default: 0.0
      t.string :number
      t.string :nature, null: false
      t.string :currency, null: false
      t.integer :journal_entry_id
      t.datetime :accounted_at
      t.stamps
    end
  end
end
