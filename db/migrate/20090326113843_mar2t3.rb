class Mar2t3 < ActiveRecord::Migration
  def self.up
    add_column :purchase_orders, :planned_on, :date
    add_column :purchase_orders, :moved_on,   :date
    add_column :purchase_order_lines, :location_id, :integer, :references=>:stock_locations, :on_delete=>:cascade, :on_update=>:cascade
    add_column :stock_moves, :generated,      :boolean, :default=>false
  end

  def self.down
    remove_column :stock_moves, :generated
    remove_column :purchase_order_lines, :location_id
    remove_column :purchase_orders, :moved_on
    remove_column :purchase_orders, :planned_on
  end


end
