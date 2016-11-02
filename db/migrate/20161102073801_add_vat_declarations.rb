class AddVatDeclarations < ActiveRecord::Migration
  def change

    create_table :vat_declarations do |t|
      t.references :financial_year, null: false, index: true
      t.references :journal_entry
      t.references :responsible
      t.text :description
      t.date :started_on, null: false
      t.date :stopped_on, null: false
      t.datetime :accounted_at
      t.string :currency, null: false
      t.string :number
      t.string :reference_number
      t.string :state
      t.stamps
    end

    create_table :vat_declaration_items do |t|
      t.references :vat_declaration, null: false, index: true
      t.references :tax, null: false, index: true
      t.decimal :collected_vat_amount, precision: 19, scale: 4
      t.decimal :deductible_vat_amount, precision: 19, scale: 4
      t.string :currency, null: false
      t.stamps
    end

    add_column :financial_years, :vat_period, :string
    add_column :financial_years, :vat_mode, :string

    add_column :journal_entries, :vat_declaration_item_id, :integer

  end
end
