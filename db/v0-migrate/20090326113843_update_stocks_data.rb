# -*- coding: utf-8 -*-
class UpdateStocksData < ActiveRecord::Migration
  def self.up
    add_column :purchase_orders, :planned_on, :date
    add_column :purchase_orders, :moved_on,   :date
    add_column :purchase_order_lines, :location_id, :integer, :references=>:stock_locations, :on_delete=>:cascade, :on_update=>:cascade
    add_column :stock_moves, :generated,      :boolean, :default=>false
    add_column :prices,      :default,        :boolean, :default=>true
    execute "UPDATE #{quoted_table_name(:deliveries)} SET planned_on = #{connection.quote(Date.today)}"
    execute "UPDATE #{quoted_table_name(:purchase_orders)} SET planned_on = #{connection.quote(Date.today)}"
    execute "INSERT INTO #{quoted_table_name(:stock_locations)}(company_id, account_id, name, created_at, updated_at) SELECT companies.id, a.id ,'Lieu de stockage par défaut', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM #{quoted_table_name(:companies)} AS companies LEFT JOIN #{quoted_table_name(:accounts)} AS a ON (a.company_id=companies.id AND a.number='3')"
    
    locations = connection.select_all("SELECT * from #{quoted_table_name(:stock_locations)}")
    if locations.size > 0
      locations = "CASE "+locations.collect{|x| "WHEN company_id=#{x['company_id']} THEN #{x['id']}" }.join(" ")+" ELSE 0 END"
      execute "UPDATE #{quoted_table_name(:sale_order_lines)} SET location_id="+locations
      execute "UPDATE #{quoted_table_name(:purchase_order_lines)} SET location_id="+locations
    end
    execute "UPDATE #{quoted_table_name(:prices)} SET #{connection.quote_column_name('default')} = #{quoted_true}"
  end

  def self.down
    remove_column :prices, :default
    remove_column :stock_moves, :generated
    remove_column :purchase_order_lines, :location_id
    remove_column :purchase_orders, :moved_on
    remove_column :purchase_orders, :planned_on
  end

end
