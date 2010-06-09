class NormalizeAccountizing < ActiveRecord::Migration

  TABLES_DELETED = [:accounts, :cashes, :companies, :document_templates, :entity_categories, :journals, :taxes]
  TABLES_DEFAULT = [:cashes, :contacts, :document_templates, :entity_categories, :prices]
  TABLES_LANGUAGE = [:document_templates, :users, :entities]
  PARAMETERS = {
    'accountancy.default_journals.sales'           => 'accountancy.journals.sales',
    'accountancy.default_journals.purchase'        => 'accountancy.journals.purchases',
    'accountancy.default_journals.bank'            => 'accountancy.journals.bank',
    'accountancy.third_accounts.clients'           => 'accountancy.accounts.third_clients',
    'accountancy.third_accounts.suppliers'         => 'accountancy.accounts.third_suppliers',
    'accountancy.major_accounts.charges'           => 'accountancy.accounts.charges',
    'accountancy.major_accounts.products'          => 'accountancy.accounts.products',
    'accountancy.minor_accounts.banks'             => 'accountancy.accounts.financial_banks',
    'accountancy.minor_accounts.cashes'            => 'accountancy.accounts.financial_cashes',
    'accountancy.minor_accounts.gains'             => 'accountancy.accounts.capital_gains',
    'accountancy.minor_accounts.losses'            => 'accountancy.accounts.capital_losses',
    'accountancy.taxes_accounts.acquisition_taxes' => 'accountancy.accounts.taxes_acquisition',
    'accountancy.taxes_accounts.collected_taxes'   => 'accountancy.accounts.taxes_collected',
    'accountancy.taxes_accounts.paid_taxes'        => 'accountancy.accounts.taxes_paid',
    'accountancy.taxes_accounts.balance_taxes'     => 'accountancy.accounts.taxes_balance',
    'accountancy.taxes_accounts.assimilated_taxes' => 'accountancy.accounts.taxes_assimilated',
    'accountancy.taxes_accounts.payback_taxes'     => 'accountancy.accounts.taxes_payback',
    'accountancy.to_accountancy.automatic'         => 'accountancy.accountize.automatic'
  }.to_a.sort{|a,b| a[0]<=>b[0]}
  RIGHTS = {
    'manage_bank_accounts' => 'manage_cashes',
    'manage_statements' => 'manage_bank_statements',
    'search_and_consult_invoices' => 'consult_invoices',
    'search_and_consult_products' => 'consult_products',
    'administrate_' => '____access_',
    'close_journals' => '____close_journals',
    'mail_listings' => 'mail_to_listings',
    'create_estimates' => 'manage_estimates',
    'manage_invoicing' => 'manage_sale_payments',
    'manage_orders' => 'manage_sale_orders',
    'create_purchases' => 'manage_purchase_orders',
    'consult_sales' => 'consult_sale_orders',
    'print_accounting_document' => 'consult_accounting_documents',
    'manage_company' => '____manage_company'
  }.to_a.sort{|a,b| a[0]<=>b[0]}


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

    rename_table :payment_modes, :sale_payment_modes
    
    rename_table :payment_parts, :sale_payment_parts
    
    rename_table :payments, :sale_payments

    create_table :purchase_payment_modes do |t|
      t.column :name,            :string,  :null=>false, :limit=>50
      t.column :with_accounting, :boolean, :null=>false, :default=>false
      t.column :cash_id,         :integer
      # t.column :draft_mode,      :boolean, :null=>false, :default=>false
      t.column :company_id,      :integer, :null=>false
    end
    
    create_table :purchase_payment_parts do |t|
      t.column :amount,      :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :downpayment, :boolean, :null=>false, :default=>false
      t.column :expense_id,  :integer, :null=>false
      t.column :payment_id,  :integer, :null=>false
      t.column :company_id,  :integer, :null=>false
    end
    
    create_table :purchase_payments do |t|
      t.column :accounted_at,      :datetime         
      t.column :amount,            :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :check_number,      :string
      t.column :created_on,        :date             
      t.column :journal_record_id, :integer
      t.column :responsible_id,    :integer, :null=>false
      t.column :payee_id,          :integer, :null=>false
      t.column :mode_id,           :integer, :null=>false
      t.column :number,            :string
      t.column :paid_on,           :date             
      t.column :parts_amount,      :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :to_bank_on,        :date,    :null=>false
      t.column :company_id,        :integer, :null=>false
    end
    

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
    add_column :cashes, :nature, :string, :limit=>16, :null=>false, :default=>"bank_account"
    execute "UPDATE cashes SET nature='cash_box' WHERE account_id IN (SELECT id FROM accounts WHERE number LIKE '53%')"

    change_column :companies, :code, :string, :limit=>16

    rename_column :contacts, :stopped_at, :deleted_at
    remove_column :contacts, :started_at
    remove_column :contacts, :closed_on
    remove_column :contacts, :deleted
    remove_column :contacts, :active

    add_column :currencies, :by_default, :boolean, :null=>false, :default=>false
    add_column :currencies, :symbol, :string, :null=>false, :default=>'-'
    execute "UPDATE currencies SET by_default=#{quoted_true}, symbol='€' WHERE code='EUR'"

    change_column :delivery_modes, :code, :string, :limit=>8

    add_column :embankments, :accounted_at, :datetime
    add_column :embankments, :journal_record_id, :integer
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
    rename_column :journal_entries, :statement_id, :bank_statement_id
    
    # > Interface don't permit to add currencies therefore there is only EURO which is the default and unique currency...
    remove_column :journal_records, :financialyear_id
    remove_column :journal_records, :status
    add_column :journal_records, :currency_debit,  :decimal, :precision=>16, :scale=>2, :default=>0.0, :null=>false
    add_column :journal_records, :currency_credit, :decimal, :precision=>16, :scale=>2, :default=>0.0, :null=>false
    add_column :journal_records, :currency_rate,   :decimal, :precision=>16, :scale=>6, :default=>0.0, :null=>false
    add_column :journal_records, :currency_id,     :integer, :default=>0, :null=>false
    add_column :journal_records, :draft_mode,      :boolean, :default=>false, :null=>false
    add_column :journal_records, :draft,           :boolean, :default=>false, :null=>false
    if (currencies=select_all("SELECT * FROM currencies")).size > 0
      execute "UPDATE journal_records SET currency_debit=debit, currency_credit=credit, currency_rate=1, currency_id=CASE "+currencies.collect{|l| "WHEN company_id=#{l['company_id']} THEN #{l['id']}"}.join(" ")+" ELSE 0 END"
    end
    execute "UPDATE journal_records SET draft=#{quoted_true}, draft_mode=#{quoted_true} WHERE id in (SELECT record_id FROM journal_entries WHERE draft=#{quoted_true})"
    execute "UPDATE journal_entries SET draft=#{quoted_true} WHERE record_id in (SELECT id FROM journal_records WHERE draft=#{quoted_true})"

    add_column :listings, :source, :text

    add_column :purchase_orders, :parts_amount, :decimal, :precision=>16, :scale=>2, :default=>0.0, :null=>false
    add_column :purchase_orders, :journal_record_id, :integer
    ppps = select_all("SELECT expense_id, sum(amount) AS total FROM sale_payment_parts WHERE expense_type='PurchaseOrder' GROUP BY expense_id")
    execute "UPDATE purchase_orders SET parts_amount=CASE "+ppps.collect{|x| "WHEN id="+x['expense_id']+" THEN "+x['total']}.join(" ")+" ELSE 0 END" if ppps.size > 0

    add_column :sale_order_lines, :reduction_percent, :decimal, :precision=>16, :scale=>2, :default=>0.0, :null=>false
    reductions = select_all("SELECT b.id AS id, round(-100*b.quantity/a.quantity,2) AS reduction from sale_order_lines AS a join sale_order_lines AS b on (a.id=b.reduction_origin_id)")
    execute "UPDATE sale_order_lines SET reduction_percent = CASE "+reductions.collect{|r| "WHEN id=#{r['id']} THEN #{r['reduction']}"}.join(" ")+" ELSE 0 END WHERE reduction_origin_id IS NOT NULL" if reductions.size > 0

    remove_column :sale_order_natures, :payment_type
    add_column :sale_order_natures, :payment_mode_id, :integer
    add_column :sale_order_natures, :payment_mode_complement, :text

    add_column :sale_payment_modes, :published, :boolean, :null=>true, :default=>false
    # add_column :sale_payment_modes, :draft_mode, :boolean, :null=>false, :default=>false
    add_column :sale_payment_modes, :with_accounting, :boolean, :null=>false, :default=>false
    add_column :sale_payment_modes, :with_embankment, :boolean, :null=>false, :default=>false
    add_column :sale_payment_modes, :with_commission, :boolean, :null=>false, :default=>false
    add_column :sale_payment_modes, :commission_percent, :decimal, :precision=>16, :scale=>2, :default=>0.0, :null=>false
    add_column :sale_payment_modes, :commission_amount,  :decimal, :precision=>16, :scale=>2, :default=>0.0, :null=>false
    add_column :sale_payment_modes, :commission_account_id, :integer
    execute "UPDATE sale_payment_modes SET with_accounting=#{quoted_true}" # , draft_mode=#{quoted_true}
    execute "UPDATE sale_payment_modes SET with_embankment=#{quoted_true} WHERE nature='check' OR nature='card' OR account_id IS NOT NULL"
    rename_column :sale_payment_modes, :bank_account_id, :cash_id
    remove_column :sale_payment_modes, :nature
    remove_column :sale_payment_modes, :mode
    # execute "INSERT INTO purchase_payment_modes (name, cash_id, with_accounting, draft_mode, company_id, created_at, updated_at) SELECT name, cash_id, (cash_id IS NOT NULL), #{quoted_true}, company_id, created_at, updated_at FROM sale_payment_modes" 
    execute "INSERT INTO purchase_payment_modes (name, cash_id, with_accounting, company_id, created_at, updated_at) SELECT name, cash_id, (cash_id IS NOT NULL), company_id, created_at, updated_at FROM sale_payment_modes"

    execute "INSERT INTO purchase_payment_parts(amount, downpayment, expense_id, payment_id, company_id, created_at, updated_at) SELECT amount, downpayment, expense_id, payment_id, company_id, created_at, updated_at FROM sale_payment_parts WHERE expense_type='PurchaseOrder'"
    execute "DELETE FROM sale_payment_parts WHERE expense_type='PurchaseOrder'"
    remove_column :sale_payment_parts, :invoice_id

    remove_column :sale_payments, :account_id
    rename_column :sale_payments, :entity_id, :payer_id
    change_column_null :sale_payments, :parts_amount, false, 0.0
    add_column :sale_payments, :receipt, :text
    add_column :sale_payments, :journal_record_id, :integer
    suppliers=select_all("SELECT payment_id, supplier_id FROM purchase_payment_parts JOIN purchase_orders ON (expense_id=purchase_orders.id)")
    suppliers=(suppliers.size>0 ?  "CASE "+suppliers.collect{|l| "WHEN id=#{l['payment_id']} THEN #{l['supplier_id']}"}.join(" ")+" ELSE 0 END" : "0")
    modes=select_all("SELECT a.id AS o, b.id AS n FROM sale_payment_modes AS a JOIN purchase_payment_modes AS b ON (a.name=b.name AND a.company_id=b.company_id)")
    modes=(modes.size>0 ? "CASE "+modes.collect{|l| "WHEN mode_id=#{l['o']} THEN #{l['n']}"}.join(" ")+" ELSE 0 END" : '0')
    purchase_cond = "id IN (SELECT payment_id FROM purchase_payment_parts)"
    execute "INSERT INTO purchase_payments(id, accounted_at, amount, check_number, created_on, responsible_id, mode_id, number, paid_on, parts_amount, to_bank_on, company_id, created_at, updated_at, payee_id)"+
                                  " SELECT id, accounted_at, amount, check_number, created_on, embanker_id,   #{modes}, number, paid_on, parts_amount, to_bank_on, company_id, created_at, updated_at, #{suppliers} FROM sale_payments WHERE #{purchase_cond}"
    execute "DELETE FROM sale_payments WHERE #{purchase_cond}"
    reset_sequence! :purchase_payments, :id

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
    for t in [:roles, :users]
      for o, n in RIGHTS
        execute "UPDATE #{t} SET rights=REPLACE(rights, '#{o}', '#{n}')"
      end
    end
    execute "UPDATE taxes SET amount=amount*100 WHERE nature='percent'"
    for o, n in PARAMETERS
      execute "UPDATE parameters SET name='#{n}' WHERE name='#{o}'"
    end
    execute "INSERT INTO parameters (name, nature, boolean_value, company_id, created_at, updated_at) SELECT 'accountancy.accountize.draft_mode', 'boolean', #{quoted_true}, id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM companies"
  end

  def self.down
    # Update some values in tables
    execute "DELETE FROM parameters WHERE name = 'accountancy.accountize.draft_mode'"
    for n, o in PARAMETERS.reverse
      execute "UPDATE parameters SET name='#{n}' WHERE name='#{o}'"
    end
    execute "UPDATE taxes SET amount=amount/100 WHERE nature='percent'"
    for t in [:users, :roles]
      for o, n in RIGHTS.reverse
        execute "UPDATE #{t} SET rights=REPLACE(rights, '#{n}', '#{o}')"
      end
    end
    execute "UPDATE users SET rights=REPLACE(rights, 'manage_bank_statements', 'manage_statements')"
    execute "UPDATE users SET rights=REPLACE(rights, 'manage_cashes', 'manage_bank_accounts')"
    execute "UPDATE roles SET rights=REPLACE(rights, 'manage_bank_statements', 'manage_statements')"
    execute "UPDATE roles SET rights=REPLACE(rights, 'manage_cashes', 'manage_bank_accounts')"
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

    # Work only if last migration !!!!
    add_column :sale_payments, :old_id, :integer
    suppliers=select_all("SELECT id, entity_id from companies")
    suppliers=(suppliers.size > 0 ? "CASE "+suppliers.collect{|l| "WHEN company_id=#{l['id']} THEN #{l['entity_id']}"}.join(" ")+" ELSE 0 END" : '0')
    modes=select_all("SELECT a.id AS n, b.id AS o FROM sale_payment_modes AS a JOIN purchase_payment_modes AS b ON (a.name=b.name AND a.company_id=b.company_id)")
    modes=(modes.size > 0 ? "CASE "+modes.collect{|l| "WHEN mode_id=#{l['n']} THEN #{l['o']}"}.join(" ")+" ELSE 0 END" : '0')
    execute "INSERT INTO sale_payments(old_id, accounted_at, amount, check_number, created_on, embanker_id,     mode_id, number, paid_on, parts_amount, to_bank_on, company_id, created_at, updated_at, payer_id)"+
                              " SELECT     id, accounted_at, amount, check_number, created_on, responsible_id, #{modes}, number, paid_on, parts_amount, to_bank_on, company_id, created_at, updated_at, #{suppliers} FROM purchase_payments"
    remove_column :sale_payments, :journal_record_id
    remove_column :sale_payments, :receipt
    # change_column_null :sale_payments, :parts_amount, false, 0.0
    rename_column :sale_payments, :payer_id, :entity_id
    add_column :sale_payments, :account_id, :integer

    add_column :sale_payment_parts, :invoice_id, :integer
    execute "INSERT INTO sale_payment_parts(amount,   downpayment,    expense_type, expense_id, payment_id,   company_id,   created_at,   updated_at)"+
                                    "SELECT p.amount, downpayment, 'PurchaseOrder', expense_id,      sp.id, p.company_id, p.created_at, p.updated_at FROM purchase_payment_parts AS p JOIN sale_payments AS sp ON (old_id=payment_id)"
    remove_column :sale_payments, :old_id

    add_column :sale_payment_modes, :mode,   :string, :null=>false, :default=>'check'
    add_column :sale_payment_modes, :nature, :string, :null=>false, :default=>"U", :limit=>1
    rename_column :sale_payment_modes, :cash_id, :bank_account_id
    remove_column :sale_payment_modes, :commission_account_id
    remove_column :sale_payment_modes, :commission_amount
    remove_column :sale_payment_modes, :commission_percent
    remove_column :sale_payment_modes, :with_commission
    remove_column :sale_payment_modes, :with_embankment
    remove_column :sale_payment_modes, :with_accounting
    # remove_column :sale_payment_modes, :draft_mode
    remove_column :sale_payment_modes, :published

    remove_column :sale_order_natures, :payment_mode_complement
    remove_column :sale_order_natures, :payment_mode_id
    add_column :sale_order_natures, :payment_type, :string, :null=>false, :default=>'none'

    remove_column :sale_order_lines, :reduction_percent

    remove_column :purchase_orders, :journal_record_id
    remove_column :purchase_orders, :parts_amount

    remove_column :listings, :source

    # > Interface don't permit to add currencies therefore there is only EURO which is the default and unique currency...
    remove_column :journal_records, :draft
    remove_column :journal_records, :draft_mode
    remove_column :journal_records, :currency_id
    remove_column :journal_records, :currency_rate
    remove_column :journal_records, :currency_credit
    remove_column :journal_records, :currency_debit
    add_column :journal_records, :status, :string, :null=>false, :default=>"A", :limit=>1
    add_column :journal_records, :financialyear_id, :integer
    if (financialyears=select_all("SELECT * FROM financialyears")).size > 0
      execute "UPDATE journal_records SET financialyear_id=CASE "+financialyears.collect{|l| "WHEN company_id=#{l['company_id']} AND printed_on BETWEEN #{quote(l['started_on'].to_date)} AND #{quote(l['stopped_on'].to_date)} THEN #{l['id']}"}.join(" ")+" ELSE 0 END"
    end
    
    rename_column :journal_entries, :bank_statement_id, :statement_id
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
    remove_column :embankments, :journal_record_id
    remove_column :embankments, :accounted_at

    # change_column :delivery_modes, :code, :string, :limit=>8

    remove_column :currencies, :symbol
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

    drop_table :purchase_payments

    drop_table :purchase_payment_parts

    drop_table :purchase_payment_modes

    rename_table :sale_payments, :payments

    rename_table :sale_payment_parts, :payment_parts
    
    rename_table :sale_payment_modes, :payment_modes
    
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
