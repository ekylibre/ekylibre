class AddTaxDeclarations < ActiveRecord::Migration
  def change
    create_table :tax_declarations do |t|
      t.references :financial_year, null: false, index: true
      t.references :journal_entry, index: true
      t.datetime :accounted_at
      t.references :responsible, index: true
      t.string :mode, null: false
      t.text :description
      t.date :started_on, null: false
      t.date :stopped_on, null: false
      t.string :currency, null: false
      t.string :number
      t.string :reference_number
      t.string :state
      t.date :invoiced_on
      t.stamps
    end

    create_table :tax_declaration_items do |t|
      t.references :tax_declaration, null: false, index: true
      t.references :tax, null: false, index: true
      t.string :currency, null: false
      t.decimal :collected_tax_amount, precision: 19, scale: 4, null: false, default: 0.0
      t.decimal :deductible_tax_amount, precision: 19, scale: 4, null: false, default: 0.0
      t.decimal :deductible_pretax_amount, precision: 19, scale: 4, null: false, default: 0.0
      t.decimal :collected_pretax_amount, precision: 19, scale: 4, null: false, default: 0.0
      t.decimal :fixed_asset_deductible_pretax_amount, precision: 19, scale: 4, null: false, default: 0.0
      t.decimal :fixed_asset_deductible_tax_amount, precision: 19, scale: 4, null: false, default: 0.0
      t.decimal :balance_pretax_amount, precision: 19, scale: 4, null: false, default: 0.0
      t.decimal :balance_tax_amount, precision: 19, scale: 4, null: false, default: 0.0
      t.stamps
    end

    add_column :financial_years, :tax_declaration_frequency, :string
    add_column :financial_years, :tax_declaration_mode, :string
    reversible do |d|
      d.up do
        execute "UPDATE financial_years SET tax_declaration_mode = 'payment'"
      end
    end
    change_column_null :financial_years, :tax_declaration_mode, false

    add_reference :journal_entry_items, :tax_declaration_item, index: true

    add_column :journals, :used_for_tax_declarations, :boolean, null: false, default: false
  end
end
