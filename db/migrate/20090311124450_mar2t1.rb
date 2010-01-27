class Mar2t1 < ActiveRecord::Migration
  def self.up

    create_table :payment_modes do |t|
      t.column :name,                   :string,   :null=>false, :limit=>50
      t.column :nature,                 :string,   :null=>false, :limit=>1, :default=>'U'        # U undefined   C check
      t.column :account_id,             :integer,  :references=>:accounts
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict 
    end
    add_index :payment_modes, :company_id
    
    create_table :payments do |t|
      t.column :paid_on,                :date
      t.column :amount,                 :decimal,  :null=>false, :precision=>16, :scale=>2
      t.column :mode_id,                :integer,  :null=>false, :references=>:payment_modes
      t.column :account_id,             :integer,  :references=>:accounts
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end
    add_index :payments, :company_id

    create_table :payment_parts do |t|
      t.column :amount,                 :decimal,  :precision=>16, :scale=>2
      t.column :payment_id,             :integer,  :null=>false, :references=>:payments
      t.column :order_id,               :integer,  :null=>false, :references=>:sale_orders
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end
    add_index :payment_parts, :company_id

    add_column :payments, :part_amount, :decimal,  :precision=>16, :scale=>2
   


    

  end



  def self.down
    #remove_column :deliveries, :delivered_on
    #remove_column :deliveries, :shipped_on
    remove_column :payments, :part_amount
    drop_table :payment_parts
    drop_table :payments
    drop_table :payment_modes
  end


end
