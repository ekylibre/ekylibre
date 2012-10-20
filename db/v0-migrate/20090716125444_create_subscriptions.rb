class CreateSubscriptions < ActiveRecord::Migration
  def self.up

    create_table :subscription_natures do |t|
      t.column :name,         :string,   :null=>false
      t.column :actual_number,:integer
      t.column :nature,       :string,   :null=>false, :limit=>8
      t.column :comment,      :text
      t.column :company_id,   :integer,  :null=>false, :references=>:companies,:on_delete=>:restrict, :on_update=>:restrict
      t.stamps
    end
    add_stamps_indexes :subscription_natures
    
    create_table :subscriptions do |t|
      t.column :started_on,        :date
      t.column :finished_on,       :date
      t.column :first_number,      :integer
      t.column :last_number,      :integer
      t.column :sale_order_id,   :integer,             :references=>:sale_orders, :on_delete=>:restrict, :on_update=>:restrict
      t.column :product_id,   :integer,  :null=>false, :references=>:products, :on_delete=>:restrict, :on_update=>:restrict
      t.column :contact_id,   :integer,  :null=>false, :references=>:contacts, :on_delete=>:restrict, :on_update=>:restrict
      t.column :company_id,   :integer,  :null=>false, :references=>:companies,:on_delete=>:restrict, :on_update=>:restrict
      t.stamps
    end
    add_stamps_indexes :subscriptions
    
    add_column :products,     :subscription_quantity, :integer
    add_column :products,     :subscription_period,   :string
    add_column :products,     :subscription_nature_id,       :integer, :references=>:subscription_natures, :on_delete=>:restrict, :on_update=>:restrict 
  end

  def self.down
    remove_column :products,  :subscription_nature_id
    remove_column :products,  :subscription_period
    remove_column :products,  :subscription_quantity
    drop_table :subscriptions
    drop_table :subscription_natures
  end
end
