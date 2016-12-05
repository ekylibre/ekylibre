class AddTaxesNeutral < ActiveRecord::Migration
  def change
    add_column :taxes, :intracommunity, :boolean, null: false, default: false
    add_reference :taxes, :intracommunity_payable_account, index: true
    add_column :tax_declaration_items, :intracommunity_payable_tax_amount, :decimal, null: false, default: 0.0, precision: 19, scale: 4
    add_column :tax_declaration_items, :intracommunity_payable_pretax_amount, :decimal, null: false, default: 0.0, precision: 19, scale: 4
  end
end
