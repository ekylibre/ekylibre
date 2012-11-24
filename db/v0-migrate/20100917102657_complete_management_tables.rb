class CompleteManagementTables < ActiveRecord::Migration
  def self.up
    create_table :cash_transfers do |t|
      t.column :emitter_cash_id,  :integer, :null=>false
      t.column :receiver_cash_id, :integer, :null=>false
      t.column :journal_entry_id, :integer
      t.column :accounted_at,     :datetime
      t.column :number,           :string,  :null=>false
      t.column :comment,          :text
      t.column :currency_id,      :integer, :null=>false
      t.column :currency_rate,    :decimal, :null=>false, :precision=>16, :scale=>6, :default=>1
      t.column :currency_amount,  :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0
      t.column :amount,           :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0
      t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
      t.stamps
    end
    add_stamps_indexes :cash_transfers
    add_index :cash_transfers, :company_id

    create_table :purchase_deliveries do |t|
      t.integer  :order_id,                                                          :null => false
      t.decimal  :amount,            :precision => 16, :scale => 2, :default => 0.0, :null => false
      t.decimal  :amount_with_taxes, :precision => 16, :scale => 2, :default => 0.0, :null => false
      t.integer  :currency_id
      t.text     :comment
      t.integer  :contact_id
      t.date     :planned_on
      t.date     :moved_on
      t.decimal  :weight,            :precision => 16, :scale => 4
      t.column   :company_id,        :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
      t.stamps
    end
    add_stamps_indexes :purchase_deliveries
    add_index :purchase_deliveries, :company_id
    add_index :purchase_deliveries, [:order_id, :company_id]

    create_table :purchase_delivery_lines do |t|
      t.integer  :delivery_id,                                                       :null => false
      t.integer  :order_line_id,                                                     :null => false
      t.integer  :product_id,                                                        :null => false
      t.integer  :price_id,                                                          :null => false
      t.decimal  :quantity,          :precision => 16, :scale => 4, :default => 1.0, :null => false
      t.integer  :unit_id,                                                           :null => false
      t.decimal  :amount,            :precision => 16, :scale => 2, :default => 0.0, :null => false
      t.decimal  :amount_with_taxes, :precision => 16, :scale => 2, :default => 0.0, :null => false
      t.integer  :tracking_id
      t.integer  :warehouse_id
      t.decimal  :weight,            :precision => 16, :scale => 4
      t.column   :company_id,        :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
      t.stamps
    end
    add_stamps_indexes :purchase_delivery_lines
    add_index :purchase_delivery_lines, :company_id
    add_index :purchase_delivery_lines, [:delivery_id, :company_id]
    add_index :purchase_delivery_lines, [:tracking_id, :company_id]
    add_index :purchase_delivery_lines, [:warehouse_id, :company_id]

    create_table :purchase_delivery_modes do |t|
      t.string   :name,                                     :null => false
      t.string   :code,         :limit => 8,                :null => false
      t.text     :comment
      t.column   :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
      t.stamps
    end
    add_stamps_indexes :purchase_delivery_modes
    add_index :purchase_delivery_modes, :company_id

    create_table :deposit_lines do |t|
      t.column   :deposit_id,       :integer, :null=>false
      t.column   :quantity,         :decimal, :null=>false, :precision=>16, :scale=>4, :default=>0.0
      t.column   :amount,           :decimal, :null=>false, :precision=>16, :scale=>2, :default=>1.0
      t.column   :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
      t.stamps
    end
    add_stamps_indexes :deposit_lines
    add_index :deposit_lines, :company_id
    add_index :deposit_lines, [:deposit_id, :company_id]

    add_column :deposits, :in_cash, :boolean, :null=>false, :default=>false
    add_column :transports, :number, :string
    add_column :transports, :reference_number, :string
    add_column :purchase_orders, :reference_number, :string

    change_column :entities, :code, :string, :limit=>64
  end

  def self.down
    remove_column :purchase_orders, :reference_number
    remove_column :transports, :reference_number
    remove_column :transports, :number
    remove_column :deposits, :in_cash

    drop_table :deposit_lines
    drop_table :purchase_delivery_modes
    drop_table :purchase_delivery_lines
    drop_table :purchase_deliveries
    drop_table :cash_transfers
  end
end
