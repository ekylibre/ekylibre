class Mar1 < ActiveRecord::Migration
  def self.up 
    add_column    :companies,        :entity_id,     :integer, :references=>:entities, :on_delete=>:cascade, :on_update=>:cascade
    add_column    :bank_accounts,    :entity_id,     :integer, :references=>:entities, :on_delete=>:cascade, :on_update=>:cascade
    add_index :bank_accounts, :entity_id

    # entity is automatically created for all the companies.
    execute "INSERT INTO entity_natures(company_id, name, in_name, physical, abbreviation, created_at, updated_at) SELECT companies.id, 'Indéfini', CAST('false' AS BOOLEAN), CAST('false' AS BOOLEAN), '-', current_timestamp, current_timestamp FROM companies LEFT JOIN entity_natures en ON (en.company_id=companies.id AND en.name='Indéfini') WHERE en.id IS NULL"
    execute "INSERT INTO entities(company_id, nature_id, language_id, name, code, full_name, created_at, updated_at) SELECT companies.id, en.id, ln.id, companies.name, companies.code, companies.name, current_timestamp, current_timestamp FROM companies LEFT JOIN entity_natures en ON (en.company_id=companies.id AND  en.name='Indéfini') LEFT JOIN entities e ON (e.code=companies.code), languages ln  WHERE ln.iso2='fr' AND e.id IS NULL"
#    execute "UPDATE companies SET entity_id=e.id FROM entities e WHERE e.code=companies.code"
    for company in Company.find(:all)
      company.entity_id = Entity.find_by_company_id_and_code(company.id, company.code).id
      company.save(false)
    end
#    execute "UPDATE bank_accounts SET entity_id=c.entity_id FROM companies c WHERE c.entity_id=bank_accounts.entity_id"
    for bank_account in BankAccount.find(:all)
      bank_account.entity_id = Company.find_by_id(bank_account.company_id).entity_id
      bank_account.save(false)
    end

#     for company in Company.find(:all)
#       nature = company.entity_natures.find(:first, :conditions=>{:in_name=>false, :physical=>false,:abbreviation=>'-'})                              
#       nature = company.entity_natures.create!(:name=>'Inconnu', :abbreviation=>'-', :in_name=>false, :physical=>false) if nature.nil?
#       entity = company.entities.find(:first, :conditions=>{:code=>company.code})
#       entity = company.entities.create!(:nature_id=>nature.id , :language_id=>1 , :name=>company.name, :code=>company.code) if entity.nil?
#       company.update_attributes({:entity_id=>entity.id})
#       company.bank_accounts.each do |bank_account|
#         bank_account.update_attributes({:entity_id=>entity.id})
#       end
#     end

    
    add_column    :contacts,         :country,        :string,  :limit=>2    
    add_column    :products,         :weight,         :decimal, :precision=>16, :scale=>3
    add_column    :entities,         :vat_submissive, :boolean, :null=>false,   :default=>true
    add_column    :entities,         :reflation_submissive,  :boolean, :null=>false, :default=>false
    add_column    :entities,         :deliveries_conditions, :string, :limit=>60
    add_column    :entities,         :discount_rate,  :decimal, :precision=>8,  :scale=>2
    add_column    :entities,         :reduction_rate, :decimal, :precision=>8,  :scale=>2
    add_column    :entities,         :comment,        :text
    add_column    :entities,         :excise,         :string,  :limit=>15
    add_column    :entities,         :vat_number,     :string,  :limit=>15
    add_column    :entities,         :country,        :string,  :limit=>2
    add_column    :entities,         :payments_number,:integer
    add_column    :products,         :without_stocks, :boolean, :null=>false, :default=>false
    add_column    :products,         :price,          :decimal, :precision=>16, :scale=>2, :default=>0.0.to_d
    add_column    :prices,           :entity_id,      :integer, :references=>:entities, :on_delete=>:cascade, :on_update=>:cascade
    add_column    :prices,           :started_at,     :timestamp
    add_column    :prices,           :stopped_at,     :timestamp
    add_column    :prices,           :active,         :boolean, :null=>false, :default=>true
    add_column    :prices,           :currency_id,    :integer, :references=>:currencies
    add_column    :deliveries,       :contact_id,     :integer, :references=>:contacts
    remove_column :delivery_lines,   :price_list_id
    remove_column :invoice_lines,    :price_list_id
    remove_column :prices,           :list_id
    remove_column :purchase_orders,  :list_id
    remove_column :sale_order_lines, :price_list_id
    remove_column :prices,           :started_on
    remove_column :prices,           :stopped_on
    remove_column :prices,           :deleted
    remove_column :prices,           :default
    drop_table :price_lists


  #   # Appellation
#     create_table :appellation do |t|
      
#     end


#     # Wine
#     create_table :wines do |t|
#       t.column :name,                   :string,   :null=>false
#       t.column :vintage,              :string,   :null=>false
#       t.column :appellation,              :string,   :null=>false
#       #       t.column :centilisation,              :string,   :null=>false
#       t.column :alcohol_degree,              :string,   :null=>false
#       #       t.column :codification,              :string,   :null=>false
#       t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
#     end
#     add_index :wines, :company_id

#     add_column    :products, :wine_id, :integer, :references=>:wines


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
    add_column    :entities,         :employee_id,    :integer, :references=>:employees

  end

  def self.down
    remove_column :entities, :employee_id
    drop_table :employees
    #drop_table :wines
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

    add_column :delivery_lines,   :price_list_id, :integer, :references=>nil
    add_column :invoice_lines,    :price_list_id, :integer, :references=>nil
    add_column :prices,           :list_id, :integer, :references=>nil
    add_column :purchase_orders,  :list_id, :integer, :references=>nil
    add_column :sale_order_lines, :price_list_id, :integer, :references=>nil

#     add_column :delivery_lines,   :price_list_id, :integer, :references=>:price_lists
#     add_column :invoice_lines,    :price_list_id, :integer, :references=>:price_lists
#     add_column :prices,           :list_id, :integer, :references=>:price_lists
#     add_column :purchase_orders,  :list_id, :integer, :references=>:price_lists
#     add_column :sale_order_lines, :price_list_id, :integer, :references=>:price_lists

    add_column :prices,           :started_on, :date
    add_column :prices,           :stopped_on, :date
    add_column :prices,           :deleted, :boolean, :null=>false, :default=>false
    add_column :prices,           :default, :boolean, :null=>false, :default=>true
    
    remove_column :deliveries, :contact_id
    remove_column :prices, :active
    remove_column :prices, :stopped_at
    remove_column :prices, :started_at
    remove_column :prices, :entity_id
    remove_column :prices, :currency_id 
    remove_column :products,  :price
    remove_column :products, :without_stocks
    remove_column :entities, :payments_number
    remove_column :entities, :country
    remove_column :entities, :vat_number
    remove_column :entities, :excise
    remove_column :entities, :comment
    remove_column :entities, :reduction_rate
    remove_column :entities, :discount_rate
    remove_column :entities, :deliveries_conditions
    remove_column :entities, :reflation_submissive
    remove_column :entities, :vat_submissive
    remove_column :products, :weight
    remove_column :contacts, :country
    remove_column :bank_accounts, :entity_id
    remove_column :companies, :entity_id
  
  end

end
