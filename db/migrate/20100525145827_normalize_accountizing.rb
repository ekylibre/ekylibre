class NormalizeAccountizing < ActiveRecord::Migration

  TABLES_DELETED = [:accounts, :cashes, :companies, :document_templates, :entity_categories, :journals, :taxes]
  TABLES_DEFAULT = [:cashes, :contacts, :document_templates, :entity_categories, :prices]
  TABLES_LANGUAGE = [:document_templates, :users, :entities]

  def self.up
    # Drop languages in order to add a universal support of languages
    # > Interface don't permit to add languages therefore there is only french which is the default and unique language...
    for table in TABLES_LANGUAGE
      add_column table, :language, :string, :limit=>3, :null=>false, :default=>"\?\?\?"
      execute "UPDATE #{table} SET language='fra'"
      remove_column table, :language_id
    end
    execute "UPDATE parameters SET string_value='fra', nature='string' WHERE name='general.language'"

    remove_index "languages", :name => "index_languages_on_iso2"
    remove_index "languages", :name => "index_languages_on_iso3"
    remove_index "languages", :name => "index_languages_on_name"
    drop_table :languages
    
    # Drop price_taxes because unused and seems to be useless
    # with VAT and GST
    remove_index :price_taxes, :name => "index_price_taxes_on_price_id_and_tax_id"
    remove_index :price_taxes, :name => "index_price_taxes_on_price_id"
    remove_index :price_taxes, :name => "index_price_taxes_on_tax_id"

    drop_table :price_taxes

    rename_table :bank_accounts, :cashes

    rename_table :bank_account_statements, :bank_statements

    # Remove "deleted"
    # > accounts, bank_accounts, companies, contacts, document_templates, entity_categories, journals, taxes
    # > users 
    for table in TABLES_DELETED
      remove_column table, :deleted
    end
    remove_column :users, :deleted_at

    # Rename "default" columns with "by_default" (Which is not a SQL word)
    # bank_accounts, contacts, document_templates, entity_categories, prices
    for table in TABLES_DEFAULT
      rename_column table, :default, :by_default
    end

    # Add/remove columns
    remove_column :accounts, :alpha
    remove_column :accounts, :groupable
    remove_column :accounts, :keep_entries
    remove_column :accounts, :letterable
    remove_column :accounts, :parent_id
    remove_column :accounts, :pointable
    remove_column :accounts, :transferable
    remove_column :accounts, :usable

    remove_column :bank_statements, :intermediate
    rename_column :bank_statements, :bank_account_id, :cash_id
    add_column :bank_statements, :currency_debit,  :decimal, :precision=>16, :scale=>2, :default=>0.0, :null=>false
    add_column :bank_statements, :currency_credit, :decimal, :precision=>16, :scale=>2, :default=>0.0, :null=>false
    execute "UPDATE bank_statements SET currency_debit=debit, currency_credit=credit"

    change_column_null :cashes, :iban, true
    change_column_null :cashes, :iban_label, true
    add_column :cashes, :nature, :string, :limit=>16, :null=>false, :default=>"BankAccount"

    change_column :companies, :code, :string, :limit=>16

    rename_column :contacts, :stopped_at, :deleted_at
    remove_column :contacts, :started_at
    remove_column :contacts, :closed_on
    remove_column :contacts, :deleted
    remove_column :contacts, :active

    add_column :currencies, :by_default, :boolean, :null=>false, :default=>false
    execute "UPDATE currencies SET by_default=#{quoted_true}"

    change_column :delivery_modes, :code, :string, :limit=>8

    add_column :embankments, :accounted_at, :datetime
    rename_column :embankments, :bank_account_id, :cash_id

    add_column :entities, :prospect, :boolean, :null=>false, :default=>false
    rename_column :entities, :name, :last_name
    add_column :entities, :name, :string, :limit=>32
    add_column :entities, :salt, :string, :limit=>64
    add_column :entities, :hashed_password, :string, :limit=>64
    add_column :entities, :locked, :boolean, :null=>false, :default=>false

    change_column :entity_natures, :abbreviation, :string, :null=>true
    remove_column :entity_natures, :title
    rename_column :entity_natures, :abbreviation, :title
    add_column :entity_natures, :format, :string
    execute "UPDATE entity_natures SET format='[title] [last_name] [first_name]' WHERE physical=#{quoted_true}"
    execute "UPDATE entity_natures SET format='[last_name]' WHERE physical=#{quoted_false}"

    rename_column :entity_links, :entity1_id, :entity_1_id
    rename_column :entity_links, :entity2_id, :entity_2_id

    rename_column :events, :user_id, :responsible_id

    rename_column :inventories, :date, :created_on
    add_column :inventories, :accounted_at, :datetime
    add_column :inventories, :number, :string, :limit=>16
    
    add_column :journal_entries, :closed, :boolean, :null=>false, :default=>false
    execute "UPDATE journal_entries SET closed = NOT COALESCE(editable, #{quoted_true})"
    remove_column :journal_entries, :editable
    remove_column :journal_entries, :currency_rate
    remove_column :journal_entries, :currency_id
    remove_column :journal_entries, :intermediate_id
    
    # > Interface don't permit to add currencies therefore there is only EURO which is the default and unique currency...
    remove_column :journal_records, :financialyear_id
    add_column :journal_records, :currency_debit,  :decimal, :precision=>16, :scale=>2, :default=>0.0, :null=>false
    add_column :journal_records, :currency_credit, :decimal, :precision=>16, :scale=>2, :default=>0.0, :null=>false
    add_column :journal_records, :currency_rate,   :decimal, :precision=>16, :scale=>6, :default=>0.0, :null=>false
    add_column :journal_records, :currency_id,     :integer, :default=>0, :null=>false
    if (currencies=select_all("SELECT * FROM currencies")).size > 0
      execute "UPDATE journal_records SET currency_debit=debit, currency_credit=credit, currency_rate=1, currency_id=CASE "+currencies.collect{|l| "WHEN company_id=#{l['company_id']} THEN #{l['id']}"}.join(" ")+" ELSE 0 END"
    end

    add_column :listings, :source, :text

    rename_column :payment_modes, :bank_account_id, :cash_id
    remove_column :payment_modes, :nature
    change_column :payment_modes, :mode, :string, :limit=>16
    rename_column :payment_modes, :mode, :nature
    add_column :payment_modes, :direction, :string, :limit=>64, :null=>false, :default=>'received' #  / given
    add_column :payment_modes, :published, :boolean, :null=>true, :default=>false
    add_column :payment_modes, :with_accounting, :boolean, :null=>false, :default=>false
    add_column :payment_modes, :with_embankment, :boolean, :null=>false, :default=>false
    add_column :payment_modes, :with_commission, :boolean, :null=>false, :default=>false
    add_column :payment_modes, :commission_percent, :decimal, :precision=>16, :scale=>2, :default=>0.0, :null=>false
    add_column :payment_modes, :commission_account_id, :integer
    execute "UPDATE payment_modes SET with_accounting=#{quoted_true}, with_embankment=(nature='check' OR nature='card')"
    execute "UPDATE payment_modes SET nature='check' WHERE LENGTH(TRIM(COALESCE(nature, ''))) <= 0"
    execute "INSERT INTO payment_modes (nature, direction, name, account_id, company_id, created_at, updated_at) SELECT nature, 'given', name, account_id, company_id, created_at, updated_at FROM payment_modes" 
    # WHERE id IN (SELECT mode_id FROM payment_parts JOIN payments ON (payment_id=payments.id) WHERE expense_type='PurchaseOrder')"

    remove_column :payments, :account_id
    add_column :payments, :receipt, :text
    add_column :payments, :direction, :string, :limit=>64, :null=>true, :default=>'received' #  / given
    suppliers=select_all("SELECT payments.id, entity_id from payment_parts JOIN payments ON (payments.id=payment_id) where expense_type='PurchaseOrder'")
    modes    =select_all("SELECT a.id AS g, b.id AS r FROM payment_modes AS a JOIN payment_modes AS b ON (a.direction='given' AND b.direction='received' AND a.nature=b.nature AND a.name=b.name AND a.company_id=b.company_id)")
    if suppliers.size > 0 and modes.size > 0
      suppliers = "CASE "+suppliers.collect{|l| "WHEN id=#{l['id']} THEN #{l['entity_id']}"}.join(" ")+" ELSE 0 END"
      modes = "CASE "+modes.collect{|l| "WHEN mode_id=#{l['r']} THEN #{l['g']}"}.join(" ")+" ELSE 0 END"
      entities  = "CASE "+select_all("SELECT * FROM companies").collect{|l| "WHEN company_id=#{l['id']} THEN #{l['entity_id']}"}.join(" ")+" ELSE 0 END"
      execute "UPDATE payments SET direction='given', entity_id=#{suppliers}, mode_id=#{modes} WHERE entity_id=#{entities}"
    end

    change_column :products, :code, :string, :limit=>16
    remove_column :products, :to_rent
    rename_column :products, :to_produce, :for_productions
    rename_column :products, :to_sale, :for_sales
    rename_column :products, :to_purchase, :for_purchases
    rename_column :products, :charge_account_id, :purchases_account_id
    rename_column :products, :product_account_id, :sales_account_id
    add_column :products, :for_immobilizations, :boolean, :null=>false, :default=>false
    add_column :products, :immobilizations_account_id, :integer
    add_column :products, :published, :boolean, :null=>false, :default=>false
    execute "UPDATE products SET published=#{quoted_true}"    

    add_column :shelves, :published, :boolean, :null=>false, :default=>false
    execute "UPDATE shelves SET published=#{quoted_true}"

    add_column :users, :connected_at, :datetime
    remove_column :users, :free_price
    remove_column :users, :credits

    # Update some values in tables
    # > Parameters, journals, percent
    execute "UPDATE document_templates SET source=REPLACE(source, 'employee', 'responsible'), cache=REPLACE(cache, 'employee', 'responsible')"
    execute "UPDATE document_templates SET nature='balance_sheet' WHERE nature='financialyear' AND code LIKE 'BILAN%'"
    execute "UPDATE document_templates SET nature='income_statement' WHERE nature='financialyear'"
    execute "UPDATE journals SET nature='sales' WHERE nature='sale'"
    execute "UPDATE journals SET nature='purchases' WHERE nature='purchase'"
    execute "UPDATE journals SET nature='forward' WHERE nature='renew'"
    execute "UPDATE parameters SET name='accountancy.journals.sales' WHERE name='accountancy.default_journals.sales'"
    execute "UPDATE parameters SET name='accountancy.journals.purchases' WHERE name='accountancy.default_journals.purchase'"
    execute "UPDATE parameters SET name='accountancy.journals.bank' WHERE name='accountancy.default_journals.bank'"
    execute "UPDATE taxes SET amount=amount*100 WHERE nature='percent'"
  end

  def self.down
    # Update some values in tables
    execute "UPDATE taxes SET amount=amount/100 WHERE nature='percent'"
    execute "UPDATE parameters SET name='accountancy.default_journals.bank' WHERE name='accountancy.journals.bank'"
    execute "UPDATE parameters SET name='accountancy.default_journals.purchase' WHERE name='accountancy.journals.purchases'"
    execute "UPDATE parameters SET name='accountancy.default_journals.sales' WHERE name='accountancy.journals.sales'"
    execute "UPDATE journals SET nature='renew' WHERE nature='forward'"
    execute "UPDATE journals SET nature='purchase' WHERE nature='purchases'"
    execute "UPDATE journals SET nature='sale' WHERE nature='sales'"

    # Add/remove columns
    add_column :users, :credits, :boolean, :null=>false, :default=>false
    add_column :users, :free_price, :boolean, :null=>false, :default=>false
    remove_column :users, :connected_at

    remove_column :shelves, :published

    remove_column :products, :published
    remove_column :products, :immobilizations_account_id
    remove_column :products, :for_immobilizations
    rename_column :products, :sales_account_id, :product_account_id
    rename_column :products, :purchases_account_id, :charge_account_id
    rename_column :products, :for_purchases, :to_purchase
    rename_column :products, :for_sales, :to_sale
    rename_column :products, :for_productions, :to_produce
    add_column :products, :to_rent, :boolean, :null=>false, :default=>false
    # change_column :products, :code, :string, :limit=>16

    if (suppliers=select_all("SELECT payments.id, entity_id from payment_parts JOIN payments ON (payments.id=payment_id) where expense_type='PurchaseOrder'")).size > 0
      suppliers = "CASE "+suppliers.collect{|l| "WHEN id=#{l['id']} THEN #{l['entity_id']}"}.join(" ")+" ELSE 0 END"
      entities  = "CASE "+select_all("SELECT * FROM companies").collect{|l| "WHEN company_id=#{l['id']} THEN #{l['entity_id']}"}.join(" ")+" ELSE 0 END"
      modes = "CASE "+select_all("SELECT a.id AS g, b.id AS r FROM payment_modes AS a JOIN payment_modes AS b ON (a.direction='given' AND b.direction='received' AND a.nature=b.nature AND a.name=b.name AND a.company_id=b.company_id)").collect{|l| "WHEN mode_id=#{l['g']} THEN #{l['r']}"}.join(" ")+" ELSE 0 END"
      execute "UPDATE payments SET entity_id=#{entities}, mode_id=#{modes} WHERE entity_id=#{suppliers}"
    end
    remove_column :payments, :direction
    remove_column :payments, :receipt
    add_column :payments, :account_id, :integer

    execute "DELETE FROM payment_modes WHERE direction='given'"
    remove_column :payment_modes, :commission_account_id
    remove_column :payment_modes, :commission_percent
    remove_column :payment_modes, :with_commission
    remove_column :payment_modes, :with_embankment
    remove_column :payment_modes, :with_accounting
    remove_column :payment_modes, :published
    remove_column :payment_modes, :direction
    rename_column :payment_modes, :nature, :mode
    # change_column :payment_modes, :mode, :string, :limit=>16
    add_column :payment_modes, :nature, :string, :limit=>1, :default=>"U"
    rename_column :payment_modes, :cash_id, :bank_account_id

    remove_column :listings, :source

    # > Interface don't permit to add currencies therefore there is only EURO which is the default and unique currency...
    remove_column :journal_records, :currency_id
    remove_column :journal_records, :currency_rate
    remove_column :journal_records, :currency_credit
    remove_column :journal_records, :currency_debit
    add_column :journal_records, :financialyear_id, :integer
    if (financialyears=select_all("SELECT * FROM financialyears")).size > 0
      execute "UPDATE journal_records SET financialyear_id=CASE "+financialyears.collect{|l| "WHEN company_id=#{l['company_id']} AND printed_on BETWEEN #{quote(l['started_on'].to_date)} AND #{quote(l['stopped_on'].to_date)} THEN #{l['id']}"}.join(" ")+" ELSE 0 END"
    end
    
    add_column :journal_entries, :intermediate_id, :integer
    add_column :journal_entries, :currency_id, :integer, :null=>false, :default=>0
    add_column :journal_entries, :currency_rate, :decimal, :null=>false, :precision=>16, :scale=>6, :default=>0.0
    add_column :journal_entries, :editable, :boolean, :null=>false, :default=>true
    if (currencies=select_all("SELECT * FROM currencies WHERE by_default")).size>0
      execute "UPDATE journal_entries SET editable = NOT closed, currency_id=CASE "+currencies.collect{|l| "WHEN company_id=#{l['company_id']} THEN #{l['id']}"}.join(" ")+" ELSE 0 END, currency_rate=1"
    end
    remove_column :journal_entries, :closed
  
    remove_column :inventories, :number
    remove_column :inventories, :accounted_at
    rename_column :inventories, :created_on, :date
    
    rename_column :events, :responsible_id, :user_id

    rename_column :entity_links, :entity_2_id, :entity2_id
    rename_column :entity_links, :entity_1_id, :entity1_id

    remove_column :entity_natures, :format
    rename_column :entity_natures, :title, :abbreviation
    add_column :entity_natures, :title, :string
    execute "UPDATE entity_natures SET title=abbreviation WHERE physical=#{quoted_true}"

    remove_column :entities, :locked
    remove_column :entities, :hashed_password
    remove_column :entities, :salt
    remove_column :entities, :name
    rename_column :entities, :last_name, :name
    remove_column :entities, :prospect

    rename_column :embankments, :cash_id, :bank_account_id
    remove_column :embankments, :accounted_at

    # change_column :delivery_modes, :code, :string, :limit=>8

    remove_column :currencies, :by_default

    add_column :contacts, :active, :boolean, :null=>false, :default=>false
    add_column :contacts, :deleted, :boolean, :null=>false, :default=>false
    add_column :contacts, :closed_on, :date
    add_column :contacts, :started_at, :datetime
    rename_column :contacts, :deleted_at, :stopped_at
    execute "UPDATE contacts SET started_at=created_at, active=(stopped_at IS NULL), deleted=(stopped_at IS NOT NULL)"

    # change_column :companies, :code, :string, :limit=>16


    remove_column :cashes, :nature
    # change_column_null :cashes, :iban_label, true
    # change_column_null :cashes, :iban, true


    remove_column :bank_statements, :currency_credit
    remove_column :bank_statements, :currency_debit
    rename_column :bank_statements, :cash_id, :bank_account_id
    add_column :bank_statements, :intermediate, :boolean, :null=>false, :default=>false

    add_column :accounts, :usable, :boolean, :null=>false, :default=>true
    add_column :accounts, :transferable, :boolean, :null=>false, :default=>false
    add_column :accounts, :pointable, :boolean, :null=>false, :default=>false
    add_column :accounts, :parent_id, :integer, :null=>false, :default=>0
    add_column :accounts, :letterable, :boolean, :null=>false, :default=>false
    add_column :accounts, :keep_entries, :boolean, :null=>false, :default=>false
    add_column :accounts, :groupable, :boolean, :null=>false, :default=>false
    add_column :accounts, :alpha, :string, :limit=>16

    # Remove by_default
    for table in TABLES_DEFAULT.reverse
      rename_column table, :by_default, :default
    end

    # Remove deleted_at/deleter_id
    add_column :users, :deleted_at, :datetime
    for table in TABLES_DELETED.reverse
      add_column table, :deleted, :boolean, :null=>false, :default=>false
    end

    rename_table :bank_statements, :bank_account_statements

    rename_table :cashes, :bank_accounts

    # Create price_taxes
    create_table :price_taxes, :force => true do |t|
      t.integer  :price_id,                      :null => false
      t.integer  :tax_id,                        :null => false
      t.decimal  :amount,       :default => 0.0, :null => false
      t.datetime :created_at,                    :null => false
      t.datetime :updated_at,                    :null => false
      t.integer  :creator_id
      t.integer  :updater_id
      t.integer  :lock_version, :default => 0,   :null => false
      t.integer  :company_id,                    :null => false
    end
    
    add_index :price_taxes, ["company_id", "price_id", "tax_id"], :name => "index_price_taxes_on_price_id_and_tax_id", :unique => true
    add_index :price_taxes, ["price_id"], :name => "index_price_taxes_on_price_id"
    add_index :price_taxes, ["tax_id"], :name => "index_price_taxes_on_tax_id"
    
    
    # Create languages
    create_table :languages do |t|
      t.column :name,                   :string, :null=>false
      t.column :native_name,            :string, :null=>false
      t.column :iso2,                   :string, :limit=>2, :null=>false
      t.column :iso3,                   :string, :limit=>3, :null=>false
      t.column :company_id,             :integer, :null=>false
    end
    add_index :languages, :name
    add_index :languages, :iso2
    add_index :languages, :iso3

    languages = nil
    if select_all("SELECT * FROM companies").size > 0
      execute "INSERT INTO languages(name, native_name, iso2, iso3, company_id, created_at, updated_at) SELECT 'French', 'Français', 'fr', 'fra', id, created_at, created_at FROM companies"
      execute "DELETE FROM parameters WHERE name='general.language'"
      execute "INSERT INTO parameters(company_id, name, nature, record_value_id, record_value_type, created_at, updated_at) SELECT company_id, 'general.language', 'record', id, 'Language', created_at, updated_at FROM languages"
      languages = "CASE "+select_all("SELECT * FROM languages").collect{|l| "WHEN company_id=#{l['company_id']} THEN #{l['id']}"}.join(" ")+" ELSE 0 END"
    end

    for table in TABLES_LANGUAGE.reverse
      add_column table, :language_id, :integer, :null=>false, :default=>0
      execute "UPDATE #{table} SET language_id=#{languages}" if languages
      remove_column table, :language
    end

  end

end
