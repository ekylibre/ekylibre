class AddPurchaseTaxPayability < ActiveRecord::Migration
  def change
    add_column :purchases, :tax_payability, :string
    reversible do |r|
      r.up do
        execute "UPDATE purchases SET tax_payability = 'at_invoicing'"
      end
    end
    change_column_null :purchases, :tax_payability, false
  end
end
