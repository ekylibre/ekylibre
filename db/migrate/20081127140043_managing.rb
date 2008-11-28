class Managing < ActiveRecord::Migration
  def self.up

    # Product
    create_table :products do |t| 
      t.column :to_purchase,            :boolean,  :null=>false
      t.column :to_sale,                :boolean,  :null=>false
      t.column :to_rent,                :boolean,  :null=>false
      t.column :name,                   :string,   :null=>false
      t.column :number,                 :integer,  :null=>false
      t.column :active,                 :boolean,  :null=>false, :default=>true
      t.column :code,                   :string,   :limit=>64, :null=>false
      t.column :code2,                  :string,   :limit=>64, :null=>false
      t.column :ean13,                  :string,   :limit=>13
      t.column :catalog_name,           :string,   :null=>false
      t.column :catalog_description,    :text
      t.column :description,            :text
      t.column :account_id,             :integer,  :null=>false, :references=>:accounts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :products, [:name, :company_id], :unique=>true
    add_index :products, [:code, :company_id], :unique=>true
    add_index :products, :company_id


    # Unit (of measure)
    create_table :units do |t|      
      t.column :name,                   :string,   :null=>false
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :units, [:name, :company_id], :unique=>true
    add_index :units, :company_id
    
    # Shelf
    create_table :shelves do |t|
      t.column :name,                   :string,   :null=>false
      t.column :catalog_name,           :string,   :null=>false
      t.column :catalog_description,    :text
      t.column :description,            :text
      t.column :parent_id,              :integer,  :references=>:shelves, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :shelves, [:name, :company_id], :unique=>true
    add_index :shelves, :company_id
    
    # 
    create_table :shelves_products do |t|
      t.column :product_id,             :integer,  :null=>false, :references=>:products, :on_delete=>:cascade, :on_update=>:cascade
      t.column :shelf_id,               :integer,  :null=>false, :references=>:shelves, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :shelves_products, [:product_id, :shelf_id], :unique=>true
    
    # Pricelist
    create_table :pricelists do |t|
      t.column :name,                   :string,   :null=>false
      t.column :code,                   :string,   :limit=>8, :null=>false
      t.column :description,            :text
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :pricelists, [:name, :company_id], :unique=>true
    add_index :pricelists, [:code, :company_id], :unique=>true
    add_index :pricelists, :company_id
    
    # PricelistItem
    create_table :pricelist_items do |t|
      t.column :price,                  :decimal,  :null=>false, :precision=>16, :scale=>4
      t.column :price_with_taxes,       :decimal,  :null=>false, :precision=>16, :scale=>4
      t.column :is_active,              :boolean,  :null=>false, :default=>true
      t.column :use_range,              :boolean,  :null=>false, :default=>false
      t.column :quantity_min,           :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :quantity_max,           :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :product_id,             :integer,  :null=>false, :references=>:products, :on_delete=>:cascade, :on_update=>:cascade
      t.column :pricelist_id,           :integer,  :null=>false, :references=>:pricelists, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :pricelist_items, :product_id
    add_index :pricelist_items, :pricelist_id
    add_index :pricelist_items, [:quantity_min, :product_id, :pricelist_id, :company_id], :unique=>true
    add_index :, :company_id
    

    # Tax
    create_table :taxes do |t|
      t.column :name,                   :string,  :null=>false
      t.column :is_reductible,          :boolean, :null=>false, :default=>true
      t.column :amount,                 :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :rate,                   :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :description,            :text
      t.column :account_id,             :integer, :null=>false, :references=>:accounts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :taxes, [:name, :company_id], :unique=>true
    add_index :, :company_id
        
    # ProductTax
    create_table :product_taxes do |t|
      t.column :amount,                 :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :product_id,             :integer, :null=>false, :references=>:products, :on_delete=>:cascade, :on_update=>:cascade
      t.column :tax_id,                 :integer, :null=>false, :references=>:taxes, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :product_taxes, [:product_id, :tax_id], :unique=>true
    add_index :, :company_id

  end

  def self.down
    drop_table :product_taxes
    drop_table :taxes
    drop_table :pricelist_items
    drop_table :pricelists
    drop_table :shelves_products
    drop_table :shelves
    drop_table :products
  end
end
