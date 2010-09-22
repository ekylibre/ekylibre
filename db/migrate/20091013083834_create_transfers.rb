class CreateTransfers < ActiveRecord::Migration
  def self.up
    create_table :transfers do |t|
      t.column :amount,       :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :parts_amount, :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :supplier_id,  :integer
      t.column :label,        :string
      t.column :comment,      :string
      # t.column :locked,       :boolean, :null=>false, :default=>false
      t.column :started_on,   :date
      t.column :stopped_on,   :date
      t.column :company_id,   :integer, :null=>false
    end
    add_index :transfers, :company_id
    
    add_column :payment_parts, :expense_type, :string,  :null=>false, :default=>'UnknownModel'
    add_column :payment_parts, :expense_id,   :integer, :null=>false, :default=>0
    execute "UPDATE #{quoted_table_name(:payment_parts)} SET expense_type='SaleOrder', expense_id=order_id"
    remove_column :payment_parts, :order_id
    add_index :payment_parts, :expense_type
    add_index :payment_parts, :expense_id
  end

  def self.down
    add_column :payment_parts, :order_id, :integer
    execute "UPDATE #{quoted_table_name(:payment_parts)} SET order_id = expense_id"
    execute "DELETE FROM #{quoted_table_name(:payment_parts)} WHERE expense_type != 'SaleOrder'"
    remove_column :payment_parts, :expense_type
    remove_column :payment_parts, :expense_id

    drop_table :transfers
  end
end
