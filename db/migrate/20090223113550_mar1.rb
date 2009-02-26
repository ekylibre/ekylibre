class Mar1 < ActiveRecord::Migration
  def self.up 
    add_column    :companies,        :entity_id,     :integer, :references=>:entities, :on_delete=>:cascade, :on_update=>:cascade
    add_column    :products,         :price,         :decimal, :precision=>16, :scale=>2, :default=>0.0.to_d
    remove_column :delivery_lines,   :price_list_id
    remove_column :invoice_lines,    :price_list_id
    remove_column :prices,           :list_id
    remove_column :purchase_orders,  :list_id
    remove_column :sale_order_lines, :price_list_id
    remove_column :prices,           :started_on
    remove_column :prices,           :stopped_on
    remove_column :prices,           :deleted
    remove_column :prices,           :default
    add_column    :prices,           :entity_id,     :integer, :null=>false, :references=>:entities, :on_delete=>:cascade, :on_update=>:cascade
    add_column    :prices,           :started_at,    :timestamp
    add_column    :prices,           :stopped_at,    :timestamp
    add_column    :prices,           :active,        :boolean, :null=>false, :default=>true
    add_column    :prices,           :currency_id,   :integer, :null=>false, :references=>:currencies
    drop_table :price_lists
  end

  def self.down
    create_table  :price_lists
    remove_column :prices, :active
    remove_column :prices, :stopped_at
    remove_column :prices, :started_at
    remove_column :prices, :entity_id
    remove_column :prices, :currency_id 
    remove_column :products,  :price
    remove_column :companies, :entity_id
  end
end
