class Sep1b6 < ActiveRecord::Migration
  def self.up
    change_column :mandates, :stopped_on, :date, :null=>true
    change_column :mandates, :started_on, :date, :null=>true
    change_column :sale_orders, :contact_id, :integer, :null=>true
    change_column :sale_orders, :invoice_contact_id, :integer, :null=>true
    change_column :sale_orders, :delivery_contact_id, :integer, :null=>true
    change_column :payment_parts, :order_id, :integer, :null=>true
    change_column :invoices, :contact_id, :integer, :null=>true
    change_column :invoice_lines, :order_line_id, :integer, :null=>true

    add_column :payment_parts, :invoice_id,  :integer, :null=>true
    add_column :payment_parts, :downpayment, :boolean, :null=>false, :default=>false
    add_column :languages, :lock_version, :integer, :null=>false, :default=>0
    add_column :entity_link_natures, :comment, :text
    add_column :entities, :webpass, :string
    add_column :payment_modes, :bank_account_id, :integer
    add_column :subscriptions, :quantity, :decimal
    add_column :subscriptions, :suspended, :boolean, :null=>false, :default=>false
    add_column :subscriptions, :nature_id, :integer
    add_column :subscriptions, :invoice_id, :integer
    add_column :subscriptions, :entity_id, :integer
    add_column :sale_orders, :annotation, :text
    add_column :invoices, :annotation, :text
    add_column :sale_order_lines, :annotation, :text
    add_column :invoice_lines, :annotation, :text
    add_column :embankments, :embanker_id, :integer

    rename_column :subscriptions, :finished_on, :stopped_on
    rename_column :invoices, :downpayment_price, :downpayment_amount
    rename_column :embankments, :payments_number, :payments_count
    rename_column :entities, :payments_number, :authorized_payments_count

    execute "UPDATE payment_parts SET downpayment=CAST('true' AS BOOLEAN) WHERE payment_id IN (SELECT id FROM payments WHERE downpayment)"

    remove_column :payments, :downpayment
    remove_column :products, :amount
  end

  def self.down
    add_column :products, :amount, :decimal
    add_column :payments, :downpayment, :boolean, :null=>false, :default=>false

    execute "UPDATE payments SET downpayment=CAST('true' AS BOOLEAN) WHERE id IN (SELECT payment_id FROM payment_parts WHERE downpayment)"

    rename_column :entities, :authorized_payments_count, :payments_number
    rename_column :embankments, :payments_count, :payments_number
    rename_column :invoices, :downpayment_amount, :downpayment_price
    rename_column :subscriptions, :stopped_on, :finished_on

    remove_column :embankments, :embanker_id
    remove_column :invoice_lines, :annotation
    remove_column :sale_order_lines, :annotation
    remove_column :invoices, :annotation
    remove_column :sale_orders, :annotation
    remove_column :subscriptions, :entity_id
    remove_column :subscriptions, :invoice_id
    remove_column :subscriptions, :nature_id
    remove_column :subscriptions, :suspended
    remove_column :subscriptions, :quantity
    remove_column :payment_modes, :bank_account_id
    remove_column :entities, :webpass
    remove_column :entity_link_natures, :comment
    remove_column :languages, :lock_version
    remove_column :payment_parts, :downpayment
    remove_column :payment_parts, :invoice_id
  end
end
