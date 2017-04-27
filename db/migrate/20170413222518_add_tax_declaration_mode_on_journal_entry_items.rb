class AddTaxDeclarationModeOnJournalEntryItems < ActiveRecord::Migration
  def change
    add_column :journal_entry_items, :tax_declaration_mode, :string
    add_index :journal_entry_items, :tax_declaration_mode
    reversible do |r|
      r.up do
        execute set_non_purchase_entry_item_tax_modes
        execute set_purchase_entry_items_debit_tax_modes
        execute set_purchase_entry_items_payment_tax_modes
      end
    end
  end

  def set_non_purchase_entry_item_tax_modes
    <<-SQL
      UPDATE journal_entry_items jeis
      SET    tax_declaration_mode = years.tax_declaration_mode
      FROM   financial_years years
      WHERE  years.id = jeis.financial_year_id
             AND jeis.tax_declaration_item_id IS NOT NULL
             AND jeis.resource_type != 'PurchaseItem'
    SQL
  end

  def set_purchase_entry_items_debit_tax_modes
    <<-SQL
      UPDATE journal_entry_items jeis
      SET    tax_declaration_mode = 'debit'
      WHERE  jeis.tax_declaration_item_id IS NOT NULL
             AND jeis.resource_type = 'PurchaseItem'
             AND jeis.resource_id IN (
               SELECT purchase_items.id
               FROM   purchase_items
               INNER JOIN purchases ON purchases.id = purchase_items.purchase_id
               WHERE purchases.tax_payability = 'at_invoicing'
             )
    SQL
  end

  def set_purchase_entry_items_payment_tax_modes
    <<-SQL
      UPDATE journal_entry_items jeis
      SET    tax_declaration_mode = 'payment'
      WHERE  jeis.tax_declaration_item_id IS NOT NULL
             AND jeis.resource_type = 'PurchaseItem'
             AND jeis.resource_id IN (
               SELECT purchase_items.id
               FROM   purchase_items
               INNER JOIN purchases ON purchases.id = purchase_items.purchase_id
               WHERE purchases.tax_payability = 'at_paying'
             )
    SQL
  end
end
