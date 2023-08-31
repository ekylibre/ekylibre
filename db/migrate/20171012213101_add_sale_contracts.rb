class AddSaleContracts < ActiveRecord::Migration[4.2]
  def change
    create_table :sale_contracts do |t|
      t.string :number
      t.string :name, null: false
      t.date :started_on
      t.date :stopped_on
      t.jsonb :custom_fields
      t.decimal :pretax_amount, precision: 19, scale: 4, default: 0.0, null: false
      t.string :currency, null: false
      t.references :responsible, index: true
      t.references :client, null: false, index: true
      t.references :sale_opportunity, index: true
      t.text :comment
      t.boolean :closed, null: false, default: false
      t.stamps
    end

    create_table :sale_contract_items do |t|
      t.references :sale_contract, null: false, index: true, foreign_key: true
      t.references :variant, null: false, index: true
      t.decimal :quantity, precision: 19, scale: 4, default: 0.0, null: false
      t.decimal :unit_pretax_amount, precision: 19, scale: 4, null: false
      t.decimal :pretax_amount, precision: 19, scale: 4, default: 0.0, null: false
      t.stamps
    end
  end
end
