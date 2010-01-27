class Sep1b7 < ActiveRecord::Migration
  def self.up
    change_column :subscriptions, :contact_id, :integer, :null=>true
    change_column :subscriptions, :product_id, :integer, :null=>true

    add_column :sale_order_lines, :entity_id, :integer
    add_column :invoice_lines, :entity_id, :integer
    add_column :products, :reduction_submissive, :boolean, :null=>false, :default=>false
    add_column :products, :unquantifiable, :boolean, :null=>false, :default=>false
    add_column :subscriptions, :comment, :text
  end

  def self.down
    remove_column :subscriptions, :comment
    remove_column :products, :unquantifiable
    remove_column :products, :reduction_submissive
    remove_column :invoice_lines, :entity_id
    remove_column :sale_order_lines, :entity_id
  end
end
