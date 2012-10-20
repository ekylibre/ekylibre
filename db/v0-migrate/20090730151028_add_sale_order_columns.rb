class AddSaleOrderColumns < ActiveRecord::Migration
  def self.up
    add_column :sale_orders, :responsible_id,  :integer, :references=>:employees, :on_delete=>:restrict, :on_update=>:restrict
    add_column :sale_orders, :letter_format,   :boolean, :null=>false, :default=>true
    add_column :sale_order_natures, :payment_type, :string, :limit=>8
  end

  def self.down
    remove_column :sale_order_natures, :payment_type
    remove_column :sale_orders, :letter_format
    remove_column :sale_orders, :responsible_id
  end
end
