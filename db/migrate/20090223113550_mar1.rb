class Mar1 < ActiveRecord::Migration
  def self.up 
    add_column    :companies,        :entity_id,     :integer, :references=>:entities, :on_delete=>:cascade, :on_update=>:cascade

    add_column    :bank_accounts,     :entity_id,     :integer, :references=>:entities, :on_delete=>:cascade, :on_update=>:cascade

    # entity is created for all the companies.
    for company in Company.find(:all)
      nature = company.entity_nature
      company.entities.create!(:nature_id=>nature.id , :language_id=>1 , :name=>company.name)
      company.update({:entity_id=>entity.id})
      company.bank_accounts.update({:entity_id=>entity.id})

    end
          


    add_column    :products,         :price,         :decimal, :precision=>16, :scale=>2, :default=>0.0.to_d
    remove_column :delivery_lines,   :price_list_id
    remove_column :invoice_lines,    :price_list_id
    remove_column :prices,           :list_id
    remove_column :purchase_orders,  :list_id
    remove_column :sale_order_lines, :price_list_id
    remove_column :prices,           :started_on
    remove_column :prices,           :stopped_on
    remove_column :prices,           :deleted
    remove_column :prices,           :default
    add_column    :prices,           :entity_id,     :integer, :null=>false, :references=>:entities, :on_delete=>:cascade, :on_update=>:cascade
    add_column    :prices,           :started_at,    :timestamp
    add_column    :prices,           :stopped_at,    :timestamp
    add_column    :prices,           :active,        :boolean, :null=>false, :default=>true
    add_column    :prices,           :currency_id,   :integer, :null=>false, :references=>:currencies
    add_column    :deliveries,       :contact_id,    :integer, :references=>:contacts
    drop_table :price_lists


    # Appellation
    create_table :appellation do |t|
      
    end


    # Wine
    create_table :wines do |t|
      t.column :name,                   :string,   :null=>false
      t.column :vintage,              :string,   :null=>false
      t.column :appellation,              :string,   :null=>false
      #       t.column :centilisation,              :string,   :null=>false
      t.column :alcohol_degree,              :string,   :null=>false
      #       t.column :codification,              :string,   :null=>false
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end
    add_index :wines, :company_id

    add_column    :products, :wine_id, :integer, :references=>:wines


    # Employee
    create_table :employees do |t|
      t.column :department_id,          :integer,  :null=>false, :references=>:departments, :on_delete=>:restrict, :on_update=>:restrict
      t.column :establishment_id,       :integer,  :null=>false, :references=>:establishments, :on_delete=>:restrict, :on_update=>:restrict
      t.column :user_id,                :integer,  :references=>:users, :on_delete=>:restrict, :on_update=>:restrict
      t.column :title,                  :string,   :null=>false, :limit=>32
      t.column :last_name,              :string,   :null=>false
      t.column :first_name,             :string,   :null=>false
      t.column :arrived_on,             :date
      t.column :departed_on,            :date
      t.column :role,                   :string
      t.column :office,                 :string,   :limit=>32
      t.column :comment,                :text
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end
    add_index :employees, :company_id


  end

  def self.down
    drop_table :employees
    drop_table :wines
    create_table  :price_lists do |t|
      t.column :name,                   :string,   :null=>false
      t.column :started_on,             :date,     :null=>false
      t.column :stopped_on,             :date
      t.column :active,                 :boolean,  :null=>false, :default=>true
      t.column :deleted,                :boolean,  :null=>false, :default=>false
      t.column :comment,                :text
      t.column :default,                :boolean,  :null=>false, :default=>true
      t.column :currency_id,            :integer,  :null=>false, :references=>:currencies
      t.column :entity_id,              :integer,  :references=>:entities,  :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :price_lists, [:name, :company_id], :unique=>true
    add_index :price_lists, :company_id
    remove_column :deliveries, :contact_id
    remove_column :prices, :active
    remove_column :prices, :stopped_at
    remove_column :prices, :started_at
    remove_column :prices, :entity_id
    remove_column :prices, :currency_id 
    remove_column :products,  :price
    remove_column :companies, :entity_id
  end
end
