class UpdateSaleOrdersState < ActiveRecord::Migration
  def self.up
    execute "UPDATE #{quoted_table_name(:sale_orders)} SET state='C' WHERE state='F'"
    execute "UPDATE #{quoted_table_name(:sale_orders)} SET state='E' WHERE state='P'"
    execute "UPDATE #{quoted_table_name(:sale_orders)} SET state='A' WHERE state NOT IN ('C', 'E')"
  end

  def self.down
    execute "UPDATE #{quoted_table_name(:sale_orders)} SET state='F' WHERE state='C'"
    execute "UPDATE #{quoted_table_name(:sale_orders)} SET state='P' WHERE state='E'"
    execute "UPDATE #{quoted_table_name(:sale_orders)} SET state='R' WHERE state='A'"
  end
end
