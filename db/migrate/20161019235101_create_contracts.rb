class CreateContracts < ActiveRecord::Migration
  def change
    create_table :contracts do |t|
      t.string :number
      t.string :description
      t.string :state
      t.string :reference_number
      t.date :started_on
      t.date :stopped_on
      t.jsonb :custom_fields
      t.decimal :pretax_amount, precision: 19, scale: 4, default: 0.0, null: false
      t.string :currency, null: false
      t.references :responsible, null: false, index: true
      t.references :supplier, null: false, index: true
      t.stamps
    end

    create_table :contract_items do |t|
      t.references :contract, null: false, index: true
      t.references :variant, null: false, index: true
      t.decimal :quantity, precision: 19, scale: 4, default: 0.0, null: false
      t.decimal :unit_pretax_amount, precision: 19, scale: 4, null: false
      t.decimal :pretax_amount, precision: 19, scale: 4, default: 0.0, null: false
      t.stamps
    end

    add_reference :purchases, :contract, index: true
    add_reference :parcels, :contract, index: true

    add_column :parcels, :pretax_amount, :decimal, precision: 19, scale: 4, default: 0.0, null: false
    add_column :parcel_items, :unit_pretax_amount, :decimal, precision: 19, scale: 4, default: 0.0, null: false
    add_column :parcel_items, :pretax_amount, :decimal, precision: 19, scale: 4, default: 0.0, null: false
  end
end
