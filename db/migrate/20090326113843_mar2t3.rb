class Mar2t3 < ActiveRecord::Migration
  def self.up
    add_column :purchase_orders, :planned_on, :date
    add_column :purchase_orders, :moved_on,   :date
    add_column :purchase_order_lines, :location_id, :integer, :references=>:stock_locations, :on_delete=>:cascade, :on_update=>:cascade
    add_column :stock_moves, :generated,      :boolean, :default=>false
    add_column :prices,      :default,        :boolean, :default=>true
    execute "UPDATE deliveries SET planned_on = current_date"
    execute "UPDATE purchase_orders SET planned_on = current_date"
    execute "INSERT INTO stock_locations(  company_id, account_id, name, created_at, updated_at)  SELECT companies.id, a.id ,'Lieu de stockage par défaut',current_timestamp, current_timestamp FROM companies LEFT JOIN accounts a ON (  a.company_id=companies.id AND a.number='3')  "
    execute "UPDATE sale_order_lines SET location_id =a.id FROM stock_locations a  WHERE a.name='Lieu de stockage par défaut' "
    execute "UPDATE purchase_order_lines SET location_id=a.id FROM stock_locations a  WHERE a.name='Lieu de stockage par défaut'"
    execute 'UPDATE prices SET "default" = true  '
  end

  def self.down
    remove_column :prices, :default
    remove_column :stock_moves, :generated
    remove_column :purchase_order_lines, :location_id
    remove_column :purchase_orders, :moved_on
    remove_column :purchase_orders, :planned_on
  end


end
