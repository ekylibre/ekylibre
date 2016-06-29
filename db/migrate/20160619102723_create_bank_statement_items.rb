class CreateBankStatementItems < ActiveRecord::Migration
  def change
    create_table :bank_statement_items do |t|
      t.references :bank_statement, null: false, unique: true, index: true
      t.string     :name,           null: false
      t.decimal    :debit,          null: false, precision: 19, scale: 4, default: 0.0
      t.decimal    :credit,         null: false, precision: 19, scale: 4, default: 0.0
      t.string     :currency,       null: false
      t.date       :transfered_on,  null: false
      t.date       :initiated_on
      t.string     :transaction_number
      t.string     :letter
      t.stamps
      t.index      :name
      t.index      :transaction_number
      t.index      :letter
    end
    add_column :journal_entry_items, :bank_statement_letter, :string
    add_index  :journal_entry_items, :bank_statement_letter
  end
end
