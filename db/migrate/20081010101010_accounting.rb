class Accounting < ActiveRecord::Migration
  def self.up
    # Currency
    create_table :currencies do |t|
      t.column :name,             :string,   :null=>false
      t.column :code,             :string,   :null=>false
      t.column :format,           :string,   :null=>false, :limit=>16
      t.column :rate,             :decimal,  :null=>false, :precision=>16, :scale=>6, :default=>1
      t.column :active,           :boolean,  :null=>false, :default=>true
      t.column :comment,          :text
      t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :currencies, :company_id
    add_index :currencies, :active
    add_index :currencies, [:code, :company_id], :unique=>true
    add_index :currencies, :name

    # Delay
    create_table :delays do |t|
      t.column :name,             :string,  :null=>false
      t.column :active,           :boolean, :null=>false, :default=>false
      t.column :expression,       :string,  :null=>false, :default=>'0'
      t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :delays, [:name, :company_id], :unique=>true
  
    # Account : Comptes comptables
    create_table :accounts do |t|
      t.column :number,           :string,  :null=>false, :limit=>16
      t.column :alpha,            :string,  :limit=>16
      t.column :name,             :string,  :null=>false, :limit=>208
      t.column :label,            :string,  :null=>false
      t.column :deleted,          :boolean, :null=>false, :default=>false
      t.column :usable,           :boolean, :null=>false, :default=>false
      t.column :groupable,        :boolean, :null=>false, :default=>false
      t.column :keep_entries,     :boolean, :null=>false, :default=>false
      t.column :transferable,     :boolean, :null=>false, :default=>false
      t.column :letterable,       :boolean, :null=>false, :default=>false
      t.column :pointable,        :boolean, :null=>false, :default=>false
      t.column :is_debit,         :boolean, :null=>false, :default=>false
      t.column :last_letter,      :string,  :limit=>8
      t.column :comment,          :text
      t.column :delay_id,         :integer, :references=>:delays, :on_delete=>:restrict, :on_update=>:cascade
      t.column :entity_id,        :integer, :references=>:entities, :on_delete=>:restrict, :on_update=>:cascade
      t.column :parent_id,        :integer, :null=>false, :default=>0, :references=>nil
      t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :accounts, [:number, :company_id], :unique=>true
    add_index :accounts, [:alpha, :company_id], :unique=>true
    add_index :accounts, [:name, :company_id]
    add_index :accounts, [:entity_id, :company_id]
    add_index :accounts, [:delay_id]
    add_index :accounts, [:entity_id]
    add_index :accounts, [:parent_id]
    add_index :accounts, [:company_id]


    # Financialyear : Exercice comptable
    create_table :financialyears do |t|
      t.column :code,             :string,  :null=>false, :limit=>12
      #t.column :nature_id,        :integer, :null=>false, :references=>:financialyear_natures
      t.column :closed,           :boolean, :null=>false, :default=>false
      t.column :started_on,       :date,    :null=>false
      t.column :stopped_on,       :date,    :null=>false
      t.column :written_on,       :date,    :null=>false  # Date butoir de création des journaux
      #t.column :debit,            :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      #t.column :credit,           :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      #t.column :position,         :integer, :null=>false
      t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :financialyears, [:code, :company_id], :unique=>true
    #add_index :financialyears, [:nature_id, :company_id]
    add_index :financialyears, :company_id

    # AccountBalance : Historique des soldes des comptes par exercice
    create_table :account_balances do |t|
      t.column :account_id,       :integer, :null=>false, :references=>:accounts,       :on_delete=>:restrict, :on_update=>:cascade
      t.column :financialyear_id, :integer, :null=>false, :references=>:financialyears, :on_delete=>:restrict, :on_update=>:cascade
      t.column :global_debit,     :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :global_credit,    :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :global_balance,   :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :global_count,     :integer, :null=>false, :default=>0
      t.column :local_debit,      :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :local_credit,     :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :local_balance,    :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :local_count,      :integer, :null=>false, :default=>0
      t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :account_balances, :company_id
    add_index :account_balances, :financialyear_id
    add_index :account_balances, [:account_id, :financialyear_id, :company_id], :unique=>true

#     # JournalNature : Type de journal
#     create_table :journal_natures do |t|
#       t.column :name,             :string,  :null=>false
#       t.column :comment,          :text
#       t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
#     end
#     add_index :journal_natures, :company_id
#     add_index :journal_natures, [:name, :company_id], :unique=>true

    # Journal : Journal
    create_table :journals do |t|
      #t.column :nature_id,        :integer, :null=>false, :references=>:journal_natures, :on_delete=>:restrict, :on_update=>:cascade
      t.column :nature,           :string,  :null=>false, :limit=>16
      t.column :name,             :string,  :null=>false
      t.column :code,             :string,  :null=>false, :limit=>4
      t.column :deleted,          :boolean, :null=>false, :default=>false
      t.column :currency_id,      :integer, :null=>false, :references=>:currencies, :on_delete=>:cascade, :on_update=>:cascade
      t.column :counterpart_id,   :integer, :references=>:accounts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :closed_on,        :date,    :null=>false, :default=>Date.civil(1970,12,31)
      t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :journals, :company_id
    add_index :journals, :currency_id
    add_index :journals, [:name, :company_id], :unique=>true
    add_index :journals, [:code, :company_id], :unique=>true

    # JournalPeriod : Période de journal
    create_table :journal_periods do |t|
      t.column :journal_id,       :integer, :null=>false, :references=>:journals, :on_delete=>:restrict, :on_update=>:cascade
      t.column :financialyear_id, :integer, :null=>false, :references=>:financialyears, :on_delete=>:restrict, :on_update=>:cascade
      t.column :started_on,       :date,    :null=>false
      t.column :stopped_on,       :date,    :null=>false
      t.column :closed,           :boolean, :default=>false
      t.column :debit,            :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :credit,           :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :balance,          :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :journal_periods, :company_id
    add_index :journal_periods, :journal_id
    add_index :journal_periods, :financialyear_id
    add_index :journal_periods, :started_on
    add_index :journal_periods, :stopped_on
    add_index :journal_periods, [:started_on, :stopped_on, :journal_id, :financialyear_id, :company_id], :unique=>true

    # JournalRecord : Piece comptable
    create_table :journal_records do |t|
      t.column :resource_id,      :integer, :references=>nil
      t.column :resource_type,    :string
      t.column :created_on,       :date,    :null=>false
      t.column :printed_on,       :date,    :null=>false
      t.column :number,           :string,  :null=>false
      t.column :status,           :string,  :null=>false, :default=>"A", :limit=>1
      t.column :debit,            :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :credit,           :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :position,         :integer, :null=>false
      t.column :period_id,        :integer, :null=>false, :references=>:journal_periods, :on_delete=>:restrict, :on_update=>:cascade
      t.column :journal_id,       :integer, :null=>false, :references=>:journals,  :on_delete=>:restrict, :on_update=>:cascade
      t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :journal_records, [:status, :company_id]
    add_index :journal_records, [:created_on, :company_id]
    add_index :journal_records, [:printed_on, :company_id]
    add_index :journal_records, :journal_id
    add_index :journal_records, :period_id
    add_index :journal_records, [:period_id, :number], :unique => true
    add_index :journal_records, :company_id
    

    # Bank : Banques
   #  create_table :banks do |t|
#       t.column :name,             :string,  :null=>false
#       t.column :code,             :string,  :null=>false, :limit=>16
#       t.column :company_id,       :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
#     end
#     add_index :banks, [:name, :company_id], :unique=>true
#     add_index :banks, [:code, :company_id], :unique=>true
#     add_index :banks, :company_id
    
    # BankAccount : Comptes bancaires
    create_table :bank_accounts do |t|
      t.column :name,             :string,  :null=>false
      t.column :bank_name,        :string
      t.column :bank_code,        :string,  :null=>false
      t.column :agency,           :string
      t.column :agency_code,      :string,  :null=>false, :limit=>16 
      t.column :number,           :string,  :null=>false, :limit=>32
      t.column :key,              :string,  :null=>false, :limit=>4
      t.column :iban,             :string,  :null=>false, :limit=>34
      t.column :iban_text,        :string,  :null=>false, :limit=>48
      t.column :bic,              :string,  :limit=>16
      t.column :deleted,          :boolean, :null=>false, :default=>false
      #t.column :bank_id,          :integer, :null=>false, :references=>:banks,      :on_delete=>:cascade, :on_update=>:cascade
      t.column :journal_id,       :integer, :null=>false, :references=>:journals,   :on_delete=>:restrict, :on_update=>:cascade
      t.column :currency_id,      :integer, :null=>false, :references=>:currencies, :on_delete=>:cascade, :on_update=>:cascade
      t.column :account_id,       :integer, :null=>false, :references=>:accounts,   :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id,       :integer, :null=>false, :references=>:companies,  :on_delete=>:cascade, :on_update=>:cascade
    end
    #add_index :bank_accounts, [:name, :bank_id, :account_id], :unique=>true
    #add_index :bank_accounts, :bank_id
    add_index :bank_accounts, :journal_id
    add_index :bank_accounts, :currency_id
    add_index :bank_accounts, :account_id
    add_index :bank_accounts, :company_id
    #add_index :bank_accounts, [:bank_id, :account_id], :unique=>true

    # BankAccountStatement : Relevé de compte
    create_table :bank_account_statements do |t|
      t.column :bank_account_id,        :integer, :null=>false, :references=>:bank_accounts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :started_on,             :date,    :null=>false
      t.column :stopped_on,             :date,    :null=>false
      #t.column :printed_on,             :date,    :null=>false
      t.column :intermediate,           :boolean, :null=>false, :default=>false
      t.column :number,                 :string,  :null=>false
      t.column :debit,                  :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :credit,                 :decimal, :null=>false, :default=>0, :precision=>16, :scale=>2
      t.column :company_id,             :integer, :null=>false, :references=>:companies,  :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :bank_account_statements, :bank_account_id
    add_index :bank_account_statements, :company_id
    
    # Entry : Écriture comptable
    create_table :entries do |t|
      t.column :record_id,              :integer,  :null=>false, :references=>:journal_records, :on_delete=>:restrict, :on_update=>:cascade
      t.column :account_id,             :integer,  :null=>false, :references=>:accounts, :on_delete=>:restrict, :on_update=>:cascade
      t.column :name,                   :string,   :null=>false
      t.column :error,                  :string
      t.column :currency_id,            :integer,  :null=>false, :references=>:currencies, :on_delete=>:restrict, :on_update=>:cascade
      t.column :currency_rate,          :decimal,  :null=>false, :precision=>16, :scale=>6
      t.column :editable,               :boolean,  :default=>true
      t.column :currency_debit,         :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0
      t.column :currency_credit,        :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0
      t.column :debit,                  :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0
      t.column :credit,                 :decimal,  :null=>false, :precision=>16, :scale=>2, :default=>0
      t.column :intermediate_id,        :integer,  :references=>:bank_account_statements, :on_delete=>:restrict, :on_update=>:cascade
      t.column :statement_id,           :integer,  :references=>:bank_account_statements, :on_delete=>:restrict, :on_update=>:cascade
      t.column :letter,                 :string,   :limit=>8
      t.column :expired_on,             :date
      t.column :position,               :integer
      t.column :comment,                :text
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :entries, :company_id
    add_index :entries, :record_id
    add_index :entries, :account_id
    add_index :entries, :statement_id
    add_index :entries, :intermediate_id
    add_index :entries, :name
    add_index :entries, :letter

  end

  def self.down
    drop_table :entries
    drop_table :bank_account_statements
    drop_table :bank_accounts
    drop_table :journal_records
    drop_table :journal_periods
    drop_table :journals
#    drop_table :journal_natures
    drop_table :account_balances
    drop_table :financialyears
    drop_table :accounts
    drop_table :delays
    drop_table :currencies
  end
end
