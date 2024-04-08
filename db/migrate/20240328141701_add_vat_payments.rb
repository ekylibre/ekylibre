class AddVatPayments < ActiveRecord::Migration[5.2]
  def change
    create_table :tax_payments do |t|
      t.datetime :accounted_at
      t.decimal :amount, precision: 19, scale: 4, null: false
      t.references :cash, index: true
      t.string :currency, null: false
      t.text :description
      t.references :financial_year, index: true, null: false
      t.references :journal_entry, index: true
      t.string :nature, null: false
      t.string :number, null: false
      t.datetime :paid_at, null: false
      t.string :state, null: false
      t.stamps
    end
  end
end


