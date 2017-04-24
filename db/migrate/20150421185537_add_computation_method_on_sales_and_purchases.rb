class AddComputationMethodOnSalesAndPurchases < ActiveRecord::Migration
  def change
    %i[sales purchases].each do |table|
      add_column table, :computation_method, :string
      reversible do |d|
        d.up do
          execute "UPDATE #{table} SET computation_method = 'tax_quantity'"
        end
      end
      change_column_null table, :computation_method, false
    end
    %i[sale_items purchase_items].each do |table|
      add_column table, :reference_value, :string
      reversible do |d|
        d.up do
          execute "UPDATE #{table} SET reference_value = CASE WHEN all_taxes_included THEN 'unit_amount' ELSE 'unit_pretax_amount' END"
        end
        d.down do
          execute "UPDATE #{table} SET all_taxes_included = CASE WHEN reference_value IN ('unit_amount', 'amount') THEN TRUE ELSE FALSE END"
        end
      end
      change_column_null table, :reference_value, false
      remove_column table, :all_taxes_included, :boolean, null: false, default: false
    end
  end
end
