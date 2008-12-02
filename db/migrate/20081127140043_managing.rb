class Managing < ActiveRecord::Migration
  def self.up

    # Unit (of measure)
    create_table :units do |t|      
      t.column :name,                   :string,   :null=>false, :limit=>8
      t.column :full_name,              :string,   :null=>false
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :units, [:name, :company_id], :unique=>true
    add_index :units, :company_id
    
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
      t.column :active,                 :boolean,  :null=>false, :default=>true
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
    add_index :pricelist_items, :company_id
    

    # Tax
    create_table :taxes do |t|
      t.column :name,                   :string,  :null=>false
      t.column :reductible,             :boolean, :null=>false, :default=>true # for the eco-particpation
      t.column :amount,                 :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :rate,                   :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :description,            :text
      t.column :account_id,             :integer, :null=>false, :references=>:accounts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :taxes, [:name, :company_id], :unique=>true
    add_index :taxes, :company_id
        
    # ProductTax
    create_table :product_taxes do |t|
      t.column :amount,                 :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :product_id,             :integer, :null=>false, :references=>:products, :on_delete=>:cascade, :on_update=>:cascade
      t.column :tax_id,                 :integer, :null=>false, :references=>:taxes, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :product_taxes, [:product_id, :tax_id], :unique=>true
    add_index :product_taxes, :company_id


    # StockLocation
    create_table :stock_locations do |t|
      t.column :name,                   :string,  :null=>false
      t.column :x,                      :string
      t.column :y,                      :string
      t.column :z,                      :string
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
#    add_index :stock_locations, :company_id

    # Stock
    create_table :stocks do |t|
      t.column :name,                   :string,  :null=>false
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
#    add_index :stock_warehouses, :company_id

    # StockMove
    create_table :stock_moves do |t|
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
#    add_index :stock_warehouses, :company_id




    






    # EstimateNature
    create_table :estimate_natures do |t|
      t.column :code,                   :string,   :limit=>16, :null=>false
      t.column :name,                   :string,   :null=>false
      t.column :expiration_id,          :integer,  :null=>false, :references=>:delays
      t.column :active,                 :boolean,  :null=>false, :default=>true
      t.column :payment_delay_id,       :integer,  :null=>false, :references=>:delays
      t.column :downpayment_rate,       :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :note,                   :text
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end    
  
    # Estimate
    create_table :estimates do |t|
      t.column :number,                 :string,   :limit=>64, :null=>false
      t.column :nature_id,              :integer,  :null=>false, :references=>:estimate_natures
      t.column :price,                  :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :taxed_price,            :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :state,                  :string,   :limit=>1, :null=>false, :default=>'O'
      t.column :expired_on,             :date,     :null=>false
      t.column :expiration_id,          :integer,  :null=>false, :references=>:delays
      t.column :payment_delay_id,       :integer,  :null=>false, :references=>:delays
      t.column :has_downpayment,        :boolean,  :null=>false, :default=>false
      t.column :downpayment_price,      :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :client_id,              :integer,  :null=>false, :references=>:entities
      t.column :contact_id,             :integer,  :null=>false, :references=>:entity_contacts
      t.column :contact_version_id,     :integer,  :null=>false, :references=>:entity_contact_versions
      t.column :invoice_contact_id,     :integer,  :null=>false, :references=>:entity_contacts
      t.column :delivery_contact_id,    :integer,  :null=>false, :references=>:entity_contacts
      t.column :object,                 :string
      t.column :function_title,         :string
      t.column :introduction,           :text
      t.column :conclusion,             :text
      t.column :note,                   :text
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
  
    # EstimateLine
    create_table :estimate_lines do |t|
      t.column :estimate_id,            :integer, :null=>false, :references=>:estimates
      t.column :product_id,             :integer, :null=>false, :references=>:products
      t.column :pricelist_id,           :integer, :null=>false, :references=>:pricelists
      t.column :price_id,               :integer, :null=>false, :references=>:pricelist_items
      t.column :price_version_id,       :integer, :null=>false, :references=>:pricelist_item_versions
      t.column :number,                 :integer, :null=>false
      t.column :quantity,               :decimal, :null=>false, :precision=>16, :scale=>2, :default=>1.0.to_d
      t.column :price,                  :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :taxed_price,            :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      # From product
      t.column :code,                   :string,  :limit=>32, :null=>false
      t.column :ean13,                  :string,  :limit=>13
      t.column :catalog_name,           :string,  :null=>false
      t.column :catalog_description,    :text
      t.column :description,            :text
      t.column :account_id,             :integer, :null=>false, :references=>:accounts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    
    # Invoice
    create_table :invoices do |t|
      t.column :nature,                 :string,  :limit=>1,  :null=>false # S Standard R Replacement C Credit(Avoir)
      t.column :number,                 :string,  :limit=>64, :null=>false
      t.column :price,                  :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :taxed_price,            :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :payment_delay_id,       :integer, :null=>false, :references=>:delays
      t.column :payment_on,             :date,          :null=>false
      t.column :has_downpayment,        :boolean, :null=>false, :default=>false
      t.column :downpayment_price,      :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :client_id,              :integer, :null=>false, :references=>:entities
      t.column :contact_id,             :integer, :null=>false, :references=>:entity_contacts
      t.column :contact_version_id,     :integer, :null=>false, :references=>:entity_contact_versions
      t.column :delivery_contact_id,    :integer, :null=>false, :references=>:entity_contacts
      t.column :delivery_contact_version_id, :integer, :null=>false, :references=>:entity_contact_versions
      t.column :object,                 :string
      t.column :function_title,         :string
      t.column :introduction,           :text
      t.column :conclusion,             :text
      t.column :note,                   :text
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    
    # Delivery
    create_table :deliveries do |t|
      t.column :estimate_id,            :integer, :null=>false, :references=>:estimates
      t.column :invoice_id,             :integer, :null=>false, :references=>:invoices
      t.column :delivered_on,           :date,    :null=>false
      t.column :price,                  :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :taxed_price,            :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    
    # DeliveryLine
    create_table :delivery_lines do |t|
      t.column :delivery_id,            :integer, :null=>false, :references=>:deliveries
      t.column :estimate_line_id,       :integer, :null=>false, :references=>:estimate_lines
      t.column :product_id,             :integer, :null=>false, :references=>:products
      t.column :pricelist_id,           :integer, :null=>false, :references=>:pricelists
      t.column :price_id,               :integer, :null=>false, :references=>:pricelist_items
      t.column :price_version_id,       :integer, :null=>false, :references=>:pricelist_item_versions
      t.column :quantity,               :decimal, :null=>false, :precision=>16, :scale=>2, :default=>1.0.to_d
      t.column :price,                  :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :taxed_price,            :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end



  
  end

  def self.down
    drop_table :delivery_lines
    drop_table :deliveries
    drop_table :invoices
    drop_table :estimate_lines
    drop_table :estimates
    drop_table :estimate_natures

    drop_table :product_taxes
    drop_table :taxes
    drop_table :pricelist_items
    drop_table :pricelists
    drop_table :shelves_products
    drop_table :shelves
    drop_table :products
  end
end
