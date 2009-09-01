class Sep1t10 < ActiveRecord::Migration
  def self.up

    add_column :sale_order_lines, :reduction_origin_id, :integer,  :references=>:sale_order_lines, :on_delete=>:cascade, :on_update=>:cascade

    add_column :subscription_natures, :reduction_rate, :decimal, :precision=>8, :scale=>2

    add_column :sale_order_lines, :label, :text
    
  end

  def self.down
    remove_column :sale_order_lines, :label
    remove_column :sale_order_lines, :reduction_origin_id
    remove_column :subscription_natures, :reduction_rate
  end
end
