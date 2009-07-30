class Sep1t6 < ActiveRecord::Migration
  def self.up
    execute "UPDATE sale_orders SET state = 'P' WHERE state = 'O'"
    add_column :payments, :parts_amount, :decimal,  :precision=>16, :scale=>2
    execute "UPDATE payments SET parts_amount = part_amount "
    remove_column :payments, :part_amount
    add_column :sale_orders, :parts_amount, :decimal,  :precision=>16, :scale=>2
    begin
      SaleOrder.find(:all).each do |sale_order|
        sale_order.save
      end
    rescue
    end
  end

  def self.down
    add_column  :payments, :part_amount, :decimal,  :precision=>16, :scale=>2
    execute "UPDATE payments SET part_amount = parts_amount "
    remove_column :sale_orders, :parts_amount
    remove_column :payments, :parts_amount
  end
end
