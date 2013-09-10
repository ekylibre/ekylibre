class CreateTransports < ActiveRecord::Migration
  def self.up

    create_table :transports do |t|
      t.column :transporter_id, :integer, :null=>false, :references=>:entities, :on_update=>:cascade, :on_delete=>:cascade
      t.column :responsible_id, :integer, :references=>:employees, :on_update=>:cascade, :on_delete=>:cascade
      t.column :weight,      :decimal
      t.column :created_on,  :date
      t.column :transport_on,:date
      t.column :comment,     :text
      t.column :company_id,  :integer, :null=>false, :references=>:companies, :on_update=>:cascade, :on_delete=>:cascade
      t.stamps
    end
    add_stamps_indexes :transports
    add_index :transports, :company_id


    add_column :deliveries, :weight,       :decimal
    add_column :deliveries, :transport_id, :integer, :references=>:transports, :on_update=>:cascade, :on_delete=>:cascade
    add_column :sale_orders, :transporter_id, :integer, :references=>:entities, :on_update=>:cascade, :on_delete=>:cascade
    add_column :deliveries, :transporter_id, :integer, :references=>:entities, :on_update=>:cascade, :on_delete=>:cascade
    add_column :entities, :transporter, :boolean, :null=>false, :default=>false

  end

  def self.down
    remove_column :entities, :transporter
    remove_column :deliveries, :transporter_id
    remove_column :sale_orders, :transporter_id
    remove_column :deliveries, :weight
    remove_column :deliveries, :transport_id
    drop_table :transports

  end
end
