class Managing < ActiveRecord::Migration
  def self.up

    # Unit (of measure)
    create_table :units do |t|      
      t.column :name,                   :string,   :null=>false, :limit=>8
      t.column :label,                  :string,   :null=>false
      t.column :base,                   :string,   :null=>false # u g m m2 m3
      t.column :quantity,               :numeric,  :null=>false, :precision=>18, :scale=>9
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :units, [:name, :company_id], :unique=>true
    add_index :units, :company_id
    
    # Shelf
    create_table :shelves do |t|
      t.column :name,                   :string,   :null=>false
      t.column :catalog_name,           :string,   :null=>false
      t.column :catalog_description,    :text
      t.column :comment,                :text
      t.column :parent_id,              :integer,  :references=>:shelves, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :shelves, [:name, :company_id], :unique=>true
    add_index :shelves, :parent_id
    add_index :shelves, :company_id


    # Product
    create_table :products do |t| 
      t.column :to_purchase,            :boolean,  :null=>false, :default=>false
      t.column :to_sale,                :boolean,  :null=>false, :default=>true
      t.column :to_rent,                :boolean,  :null=>false, :default=>false
      t.column :nature,                 :string,   :null=>false, :limit=>8  # service / product
      t.column :supply_method,          :string,   :null=>false, :limit=>8  # buy / produce
      t.column :name,                   :string,   :null=>false
      t.column :number,                 :integer,  :null=>false
      t.column :active,                 :boolean,  :null=>false, :default=>true
      t.column :amount,                 :decimal,  :null=>false, :precision=>16, :scale=>4, :default=>0.0.to_d
      t.column :code,                   :string,   :limit=>64
      t.column :code2,                  :string,   :limit=>64
      t.column :ean13,                  :string,   :limit=>13
      t.column :catalog_name,           :string,   :null=>false
      t.column :catalog_description,    :text
      t.column :description,            :text
      t.column :comment,                :text
      t.column :service_coeff,          :float     # used for price lists computing
      t.column :shelf_id,               :integer,  :null=>false, :references=>:shelves, :on_delete=>:cascade, :on_update=>:cascade
      t.column :unit_id,                :integer,  :null=>false, :references=>:units, :on_delete=>:cascade, :on_update=>:cascade
      t.column :account_id,             :integer,  :null=>false, :references=>:accounts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :products, [:name, :company_id], :unique=>true
    add_index :products, [:code, :company_id], :unique=>true
    add_index :products, :shelf_id
    add_index :products, :unit_id
    add_index :products, :account_id
    add_index :products, :company_id

    # Tax
    create_table :taxes do |t|
      t.column :name,                   :string,   :null=>false
      t.column :group_name,             :string,   :null=>false
      t.column :included,               :boolean,  :null=>false, :default=>false # for the eco-participation
      t.column :reductible,             :boolean,  :null=>false, :default=>true  # for the eco-participation
      t.column :nature,                 :string,   :null=>false, :limit=>8 # amount percent
      t.column :amount,                 :decimal,  :null=>false, :precision=>16, :scale=>4, :default=>0.0.to_d
      t.column :description,            :text
      t.column :account_collected_id,   :integer,  :references=>:accounts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :account_paid_id,        :integer,  :references=>:accounts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :taxes, [:name, :company_id], :unique=>true
    add_index :taxes, [:nature, :company_id]
    add_index :taxes, [:group_name, :company_id]
    add_index :taxes, :account_collected_id
    add_index :taxes, :account_paid_id
    add_index :taxes, :company_id
        
    # PriceList
    create_table :price_lists do |t|
      t.column :name,                   :string,   :null=>false
      t.column :started_on,             :date,     :null=>false
      t.column :stopped_on,             :date
      t.column :active,                 :boolean,  :null=>false, :default=>true
      t.column :deleted,                :boolean,  :null=>false, :default=>false
      t.column :comment,                :text
      t.column :currency_id,            :integer,  :null=>false, :references=>:currencies
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :price_lists, [:name, :company_id], :unique=>true
    add_index :price_lists, :company_id
    
    # PricelistVersion
    #     create_table :pricelist_versions do |t|
    #       t.column :name,                   :string,   :null=>false
    #       t.column :active,                 :boolean,  :null=>false, :default=>true
    #       t.column :started_on,             :date,     :null=>false
    #       t.column :stopped_on,             :date,     :null=>false
    #       t.column :comment,                :text
    #       t.column :currency_id,            :integer,  :null=>false, :references=>:currencies
    #       t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    #     end
    #     add_index :pricelist_versions, [:name, :company_id], :unique=>true
    #     add_index :pricelist_versions, :currency_id
    #     add_index :pricelist_versions, :company_id
    
    # Price
    create_table :prices do |t|
      t.column :amount,                 :decimal,  :null=>false, :precision=>16, :scale=>4
      t.column :amount_with_taxes,      :decimal,  :null=>false, :precision=>16, :scale=>4
      t.column :started_on,             :date,     :null=>false
      t.column :stopped_on,             :date
      t.column :deleted,                :boolean,  :null=>false, :default=>false
      t.column :use_range,              :boolean,  :null=>false, :default=>false
      t.column :quantity_min,           :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :quantity_max,           :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :product_id,             :integer,  :null=>false, :references=>:products, :on_delete=>:cascade, :on_update=>:cascade
      t.column :list_id,                :integer,  :null=>false, :references=>:price_lists, :on_delete=>:cascade, :on_update=>:cascade
      # t.column :pricelist_version_id,   :integer,  :null=>false, :references=>:pricelist_versions, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :prices, :product_id
    add_index :prices, :deleted
    add_index :prices, :list_id
    add_index :prices, :company_id


    # PriceTax
    create_table :price_taxes do |t|
      t.column :price_id,               :integer,  :null=>false, :references=>:prices, :on_delete=>:cascade, :on_update=>:cascade
      t.column :tax_id,                 :integer,  :null=>false, :references=>:taxes, :on_delete=>:cascade, :on_update=>:cascade
      t.column :amount,                 :decimal,  :null=>false, :precision=>16, :scale=>4, :default=>0.0.to_d
    end
    add_index :price_taxes, [:price_id, :tax_id], :unique=>true
    add_index :price_taxes, :tax_id
    add_index :price_taxes, :price_id





    # StockLocation
    create_table :stock_locations do |t|
      t.column :name,                   :string,   :null=>false
      t.column :x,                      :string
      t.column :y,                      :string
      t.column :z,                      :string
      t.column :comment,                :text
      t.column :parent_id,              :integer,  :references=>:stock_locations, :on_delete=>:cascade, :on_update=>:cascade
      t.column :account_id,             :integer,  :null=>false, :references=>:accounts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :establishment_id,       :integer,  :references=>:establishments, :on_delete=>:cascade, :on_update=>:cascade
      t.column :contact_id,             :integer,  :references=>:contacts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :stock_locations, :company_id

    # StockTracking
    create_table :stock_trackings do |t|
      t.column :name,                   :string,    :null=>false
      t.column :serial,                 :string
      t.column :active,                 :boolean,   :null=>false, :default=>true
      t.column :begun_at,               :timestamp, :null=>false
      t.column :comment,                :text
      t.column :company_id,             :integer,   :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :stock_trackings, :company_id

    # StockMove
    create_table :stock_moves do |t|
      t.column :name,                   :string,   :null=>false
      t.column :planned_on,             :date,     :null=>false
      t.column :moved_on,               :date      
      t.column :quantity,               :float,    :null=>false
      t.column :comment,                :text
      t.column :second_move_id,         :integer,  :references=>:stock_moves, :on_delete=>:cascade, :on_update=>:cascade
      t.column :second_location_id,     :integer,  :references=>:stock_locations, :on_delete=>:cascade, :on_update=>:cascade
      t.column :tracking_id,            :integer,  :references=>:stock_trackings, :on_delete=>:cascade, :on_update=>:cascade
      t.column :location_id,            :integer,  :null=>false, :references=>:stock_locations, :on_delete=>:cascade, :on_update=>:cascade
      t.column :unit_id,                :integer,  :null=>false, :references=>:units, :on_delete=>:cascade, :on_update=>:cascade
      t.column :product_id,             :integer,  :null=>false, :references=>:products, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :stock_moves, :company_id



    # Sequences
    create_table :sequences do |t|
      t.column :name,                   :string,   :null=>false
      t.column :increment,              :integer,  :null=>false, :default=>1
      t.column :format,                 :string,   :null=>false
      t.column :active,                 :boolean,  :null=>false
      t.column :next_number,            :integer,  :null=>false, :default=>0
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :sequences, :company_id



    # Delay
    create_table :delays do |t|
      t.column :name,             :string,  :null=>false
      t.column :active,           :boolean, :null=>false, :default=>true
      t.column :expression,       :string,  :null=>false
      t.column :comment,          :text
      t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :delays, [:name, :company_id], :unique=>true


    # SaleOrderNature
    create_table :sale_order_natures do |t|
      t.column :name,                   :string,   :null=>false
      t.column :expiration_id,          :integer,  :null=>false, :references=>:delays
      t.column :active,                 :boolean,  :null=>false, :default=>true
      t.column :payment_delay_id,       :integer,  :null=>false, :references=>:delays
      t.column :downpayment,            :boolean,  :null=>false, :default=>false
      t.column :downpayment_minimum,    :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :downpayment_rate,       :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :comment,                :text
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end    
    add_index :sale_order_natures, :company_id
  
    # SaleOrder
    create_table :sale_orders do |t|
      t.column :client_id,              :integer,  :null=>false, :references=>:entities
      t.column :nature_id,              :integer,  :null=>false, :references=>:sale_order_natures
      t.column :created_on,             :date,     :null=>false
      t.column :number,                 :string,   :null=>false, :limit=>64
      t.column :sum_method,             :string,   :null=>false, :limit=>8, :default=>'wt'
      t.column :invoiced,               :boolean,  :null=>false, :default=>false
      t.column :amount,                 :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :amount_with_taxes,      :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :state,                  :string,   :null=>false, :limit=>1, :default=>'O'
      t.column :expiration_id,          :integer,  :null=>false, :references=>:delays
      t.column :expired_on,             :date,     :null=>false
      t.column :payment_delay_id,       :integer,  :null=>false, :references=>:delays
      t.column :has_downpayment,        :boolean,  :null=>false, :default=>false
      t.column :downpayment_amount,     :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :contact_id,             :integer,  :null=>false, :references=>:contacts
      t.column :invoice_contact_id,     :integer,  :null=>false, :references=>:contacts
      t.column :delivery_contact_id,    :integer,  :null=>false, :references=>:contacts
      t.column :subject,                :string
      t.column :function_title,         :string
      t.column :introduction,           :text
      t.column :conclusion,             :text
      t.column :comment,                :text
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :sale_orders, :company_id
  
    # SaleOrderLine
    create_table :sale_order_lines do |t|
      t.column :order_id,               :integer, :null=>false, :references=>:sale_orders
      t.column :product_id,             :integer, :null=>false, :references=>:products
      t.column :price_list_id,          :integer, :null=>false, :references=>:price_lists
      t.column :price_id,               :integer, :null=>false, :references=>:prices
      t.column :invoiced,               :boolean, :null=>false, :default=>false
      t.column :quantity,               :decimal, :null=>false, :precision=>16, :scale=>2, :default=>1.0.to_d
      t.column :unit_id,                :integer, :null=>false, :references=>:units
      t.column :amount,                 :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :amount_with_taxes,      :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :position,               :integer
      t.column :account_id,             :integer, :null=>false, :references=>:accounts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :sale_order_lines, :company_id

    # Invoice
    create_table :invoices do |t|
      t.column :client_id,              :integer, :null=>false, :references=>:entities
      t.column :nature,                 :string,  :null=>false, :limit=>1  # S Standard R Replacement C Credit(Avoir) P Purchase
      t.column :number,                 :string,  :null=>false, :limit=>64
      t.column :amount,                 :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :amount_with_taxes,      :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :payment_delay_id,       :integer, :null=>false, :references=>:delays
      t.column :payment_on,             :date,    :null=>false
      t.column :paid,                   :boolean, :null=>false, :default=>false
      t.column :lost,                   :boolean, :null=>false, :default=>false
      t.column :has_downpayment,        :boolean, :null=>false, :default=>false
      t.column :downpayment_price,      :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :contact_id,             :integer, :null=>false, :references=>:contacts
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :invoices, :company_id

    # InvoiceLine
    create_table :invoice_lines do |t|
      t.column :invoice_id,             :integer, :null=>false, :references=>:sale_orders
      t.column :order_line_id,          :integer, :null=>false, :references=>:sale_order_lines
      t.column :product_id,             :integer, :null=>false, :references=>:products
      t.column :price_list_id,          :integer, :null=>false, :references=>:price_lists
      t.column :price_id,               :integer, :null=>false, :references=>:prices
      t.column :quantity,               :decimal, :null=>false, :precision=>16, :scale=>2, :default=>1.0.to_d
      t.column :amount,                 :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :amount_with_taxes,      :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :position,               :integer
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :invoice_lines, :company_id
    
    # Delivery
    create_table :deliveries do |t|
      t.column :order_id,               :integer, :null=>false, :references=>:sale_orders
      t.column :invoice_id,             :integer, :references=>:invoices
      t.column :shipped_on,             :date,    :null=>false
      t.column :delivered_on,           :date,    :null=>false
      t.column :amount,                 :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :amount_with_taxes,      :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :comment,                :text
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :deliveries, :company_id
    
    # DeliveryLine
    create_table :delivery_lines do |t|
      t.column :delivery_id,            :integer, :null=>false, :references=>:deliveries
      t.column :order_line_id,          :integer, :null=>false, :references=>:sale_order_lines
      t.column :product_id,             :integer, :null=>false, :references=>:products
      t.column :price_list_id,          :integer, :null=>false, :references=>:price_lists
      t.column :price_id,               :integer, :null=>false, :references=>:prices
      t.column :quantity,               :decimal, :null=>false, :precision=>16, :scale=>2, :default=>1.0.to_d
      t.column :unit_id,                :integer, :null=>false, :references=>:units
      t.column :amount,                 :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :amount_with_taxes,      :decimal, :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :delivery_lines, :company_id

    # PurchaseOrder
    create_table :purchase_orders do |t|
      t.column :client_id,              :integer,  :null=>false, :references=>:entities
      t.column :number,                 :string,   :null=>false, :limit=>64
      t.column :shipped,                :boolean,  :null=>false, :default=>false
      t.column :invoiced,               :boolean,  :null=>false, :default=>false
      t.column :amount,                 :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :amount_with_taxes,      :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :dest_contact_id,        :integer,  :null=>false, :references=>:contacts
      t.column :comment,                :text
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :purchase_orders, :company_id
  
    # PurchaseOrderLine
    create_table :purchase_order_lines do |t|
      t.column :order_id,               :integer,  :null=>false, :references=>:purchase_orders
      t.column :product_id,             :integer,  :null=>false, :references=>:products
      t.column :unit_id,                :integer,  :null=>false, :references=>:units
      t.column :quantity,               :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>1.0.to_d
      t.column :amount,                 :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :amount_with_taxes,      :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0.0.to_d
      t.column :position,               :integer
      t.column :account_id,             :integer,  :null=>false, :references=>:accounts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :purchase_order_lines, :company_id



  
  end

  def self.down
    drop_table :purchase_order_lines
    drop_table :purchase_orders
    drop_table :delivery_lines
    drop_table :deliveries
    drop_table :invoice_lines
    drop_table :invoices
    drop_table :sale_order_lines
    drop_table :sale_orders
    drop_table :sale_order_natures
    drop_table :delays
    drop_table :sequences
    drop_table :stock_moves
    drop_table :stock_trackings
    drop_table :stock_locations
    drop_table :price_taxes
    drop_table :prices
    drop_table :price_lists
    drop_table :taxes
    drop_table :products
    drop_table :shelves
    drop_table :units
  end
end
