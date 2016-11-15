class AddTaxDeclarations < ActiveRecord::Migration
  def change
    create_table :tax_declarations do |t|
      t.references :financial_year, null: false, index: true
      t.references :journal_entry, index: true
      t.references :responsible, index: true
      t.text :description
      t.date :started_on, null: false
      t.date :stopped_on, null: false
      t.datetime :accounted_at
      t.string :currency, null: false
      t.string :number
      t.string :reference_number
      t.string :state
      t.references :affair, index: true
      t.references :tax_office, index: true
      t.datetime :invoiced_at
      t.stamps
    end

    create_table :tax_declaration_items do |t|
      t.references :tax_declaration, null: false, index: true
      t.references :tax, null: false, index: true
      t.string :currency, null: false
      t.decimal :collected_tax_amount, precision: 19, scale: 4
      t.decimal :deductible_tax_amount, precision: 19, scale: 4
      t.decimal :deductible_pretax_amount, precision: 19, scale: 4
      t.decimal :collected_pretax_amount, precision: 19, scale: 4
      t.decimal :fixed_asset_deductible_pretax_amount, precision: 19, scale: 4
      t.decimal :fixed_asset_deductible_tax_amount, precision: 19, scale: 4
      t.stamps
    end

    add_column :financial_years, :tax_period, :string
    add_column :financial_years, :tax_mode, :string

    add_reference :journal_entry_items, :tax_declaration_item, index: true

    add_reference :journal_entries, :tax_declaration, index: true

    add_reference :sale_items, :tax_declaration_item, index: true
    add_reference :purchase_items, :tax_declaration_item, index: true
  end
end
