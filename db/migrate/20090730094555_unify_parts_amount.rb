class UnifyPartsAmount < ActiveRecord::Migration
  def self.up
    execute "UPDATE #{quote_table_name(:sale_orders)} SET state = 'P' WHERE state = 'O'"
    add_column :payments, :parts_amount, :decimal,  :precision=>16, :scale=>2
    execute "UPDATE #{quote_table_name(:payments)} SET parts_amount = part_amount "
    remove_column :payments, :part_amount

    add_column :sale_orders, :parts_amount, :decimal,  :precision=>16, :scale=>2
    for order in connection.select_all("SELECT id FROM #{quote_table_name(:sale_orders)}")
      execute "UPDATE #{quote_table_name(:sale_orders)} SET parts_amount=(SELECT sum(amount) FROM #{quote_table_name(:payment_parts)} WHERE order_id=#{order['id']}) WHERE id=#{order['id']}"
    end
#     begin
#       for sale_order in SaleOrder.all
#         sale_order.save
#       end
#     rescue
#     end
  end

  def self.down
    add_column  :payments, :part_amount, :decimal,  :precision=>16, :scale=>2
    execute "UPDATE #{quote_table_name(:payments)} SET part_amount = parts_amount "
    remove_column :sale_orders, :parts_amount
    remove_column :payments, :parts_amount
  end
end
