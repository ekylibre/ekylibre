class CompleteVatDeclarations < ActiveRecord::Migration
  def change

    add_column :vat_declaration_items, :deductible_pretax_amount, :decimal, precision: 19, scale: 4
    add_column :vat_declaration_items, :collected_pretax_amount, :decimal, precision: 19, scale: 4

    add_column :journal_entry_items, :vat_declaration_item_id, :integer
    remove_column :journal_entries, :vat_declaration_item_id, :integer

    add_column :sale_items, :vat_declaration_item_id, :integer
    add_column :purchase_items, :vat_declaration_item_id, :integer
    add_column :sales, :vat_declaration_item_id, :integer
    add_column :purchases, :vat_declaration_item_id, :integer
    add_column :outgoing_payments, :vat_declaration_id, :integer
    add_column :incoming_payments, :vat_declaration_id, :integer

  end
end
