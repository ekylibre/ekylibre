class Mar2 < ActiveRecord::Migration
  def self.up
     #remove_column :invoice_id, 
 #   remove_column :invoice_lines, :invoice_id
#    add_column :invoice_lines,    :invoice_id,    :integer,  :references=>nil
    remove_column :invoice_lines, :invoice_id
    add_column :invoice_lines,    :invoice_id,    :integer,  :references=>:invoices
    add_column :invoices,         :sale_order_id, :integer,  :references=>:sale_orders
  end

  def self.down
    remove_column :invoices,      :sale_order_id
    remove_column :invoice_lines, :invoice_id
    add_column :invoice_lines,    :invoice_id,    :integer,  :references=>nil
    #add_column :invoice_id,             :integer, :null=>false, :references=>:invoices
    #add_column :invoice_id,             :integer, :null=>false, :references=>:sale_orders
  end
end
