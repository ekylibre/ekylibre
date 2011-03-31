class AddSaleInformations < ActiveRecord::Migration
  def self.up
    add_column :entity_categories, :code, :string, :limit=>8
    add_index :entity_categories, [:code, :company_id], :unique=>true
    add_column :invoices, :origin_id, :integer, :references=>:invoices, :on_update=>:restrict, :on_delete=>:restrict
    add_column :invoices, :credit,    :boolean, :null=>false,  :default=>false
    add_column :invoice_lines, :origin_id, :integer, :references=>:invoice_lines, :on_update=>:restrict, :on_delete=>:restrict
    add_column :users,  :credits,  :boolean, :null=>false, :default=>true
    add_column :invoices, :created_on, :date
    add_column :payments, :to_bank_on, :date, :null=>false, :default=>Date.today
    
    execute "UPDATE entity_categories SET code="+substr("REPLACE(code, ' ', '_')", 1, 8)+" WHERE "+length(trim("COALESCE(code, '')"))+" <= 0"
    if connection.adapter_name.lower == "sqlserver"
      execute "UPDATE invoices SET created_on = created_at WHERE created_on IS NULL" 
    else
      execute "UPDATE invoices SET created_on = CAST(created_at AS DATE) WHERE created_on IS NULL" 
    end
    execute "UPDATE payment_modes SET mode=CASE WHEN LOWER(name) LIKE '%ch%' THEN 'check' ELSE 'other' END"    
  end
  
  def self.down
    remove_column :payments, :to_bank_on
    remove_column :invoices, :created_on
    remove_column :users, :credits
    remove_column :invoice_lines, :origin_id
    remove_column :invoices, :credit
    remove_column :invoices, :origin_id
    remove_column :entity_categories, :code
  end
end
