class ReviewFinancialModels < ActiveRecord::Migration
  def up
    add_column :financial_years, :currency_precision, :integer
    execute "UPDATE #{quoted_table_name(:financial_years)} SET currency_precision = 2"

    add_column :cashes, :country, :string, :limit=>2
    execute "UPDATE #{quoted_table_name(:cashes)} SET country = 'fr'"

    remove_column :cash_transfers, :currency
    remove_column :cash_transfers, :emitter_currency
    remove_column :cash_transfers, :receiver_currency
    remove_column :cash_transfers, :receiver_currency_rate
    rename_column :cash_transfers, :emitter_currency_rate, :currency_rate

    add_column :incoming_payment_modes, :depositables_journal_id, :integer
    journals = connection.select_all("SELECT id, journal_id FROM #{quoted_table_name(:cashes)}")
    execute "UPDATE #{quoted_table_name(:incoming_payment_modes)} SET depositables_journal_id = CASE "+journals.collect{|r| "WHEN cash_id=#{r['id']} THEN #{r['journal_id']}"}.join(" ")+" END WHERE with_deposit" if journals.size > 0

    add_column :sale_natures, :with_accounting, :boolean, :null=>false, :default=>false
    add_column :sale_natures, :currency, :string, :limit=>3
    add_column :sale_natures, :journal_id, :integer
    sales_journals = connection.select_all("SELECT record_value_id AS id, company_id FROM #{quoted_table_name(:preferences)} WHERE name = 'sales_journal' AND record_value_id IS NOT NULL")
    execute "UPDATE #{quoted_table_name(:sale_natures)} SET with_accounting = #{quoted_true}, currency ='EUR', journal_id=CASE "+sales_journals.collect{|r| "WHEN company_id=#{r['company_id']} THEN #{r['id']}"}.join(" ")+" END" if sales_journals.size > 0
    sales_journals = connection.select_all("SELECT id, company_id FROM #{quoted_table_name(:journals)} WHERE nature = 'sales' AND currency = 'EUR'")
    execute "UPDATE #{quoted_table_name(:sale_natures)} SET journal_id=CASE "+sales_journals.collect{|r| "WHEN company_id=#{r['company_id']} THEN #{r['id']}"}.join(" ")+" END WHERE journal_id IS NULL" if sales_journals.size > 0

    add_column :journal_entries, :financial_year_id, :integer
    for fy in connection.select_all("SELECT id, company_id, started_on, stopped_on FROM #{quoted_table_name(:financial_years)}")
      execute "UPDATE #{quoted_table_name(:journal_entries)} SET financial_year_id=#{fy['id']} WHERE company_id=#{fy['company_id']} AND printed_on BETWEEN '#{fy['started_on']}' AND '#{fy['stopped_on']}'"
    end

    create_table :purchase_natures do |t|
      t.belongs_to :company
      t.boolean :active, :null=>false, :default=>false
      t.string :name
      t.text :comment
      t.string :currency, :limit=>3
      t.boolean :with_accounting, :null=>false, :default=>false
      t.belongs_to :journal
    end
    add_stamps :purchase_natures
    add_index :purchase_natures, :company_id
    add_index :purchase_natures, :journal_id
    add_index :purchase_natures, :currency

    add_column :purchases, :nature_id, :integer

    execute("INSERT INTO #{quoted_table_name(:purchase_natures)} (company_id, name, active, with_accounting, journal_id, currency, created_at, updated_at) SELECT DISTINCT p.company_id, 'Default purchase type '||p.currency, 1=1, j.id IS NOT NULL, j.id, p.currency, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM #{quoted_table_name(:purchases)} AS p LEFT JOIN #{quoted_table_name(:journals)} AS j ON (p.company_id=j.company_id AND p.currency = j.currency AND j.nature='purchases')")
    natures = connection.select_all("SELECT id, company_id, currency FROM #{quoted_table_name(:purchase_natures)}")
    if natures.size > 0
      execute("UPDATE #{quoted_table_name(:purchases)} SET nature_id = CASE "+natures.collect{|r| "WHEN company_id=#{r['company_id']} AND currency='#{r['currency']}' THEN #{r['id']}"}.join(" ")+" END")
    end

    add_index :entities, :code
  end

  def down
    remove_index :entities, :code

    remove_column :purchases, :nature_id
    drop_table :purchase_natures

    remove_column :journal_entries, :financial_year_id

    remove_column :sale_natures, :journal_id
    remove_column :sale_natures, :currency
    remove_column :sale_natures, :with_accounting

    remove_column :incoming_payment_modes, :depositables_journal_id

    rename_column :cash_transfers, :currency_rate, :emitter_currency_rate
    add_column :cash_transfers, :receiver_currency_rate, :decimal, :precision=>19, :scale=>10
    add_column :cash_transfers, :receiver_currency, :string, :limit=>3
    add_column :cash_transfers, :emitter_currency, :string, :limit=>3
    add_column :cash_transfers, :currency, :string, :limit=>3
    execute "UPDATE #{quoted_table_name(:cash_transfers)} SET receiver_currency_rate=1, receiver_currency='EUR', emitter_currency='EUR', currency='EUR'"

    remove_column :cashes, :country
    
    remove_column :financial_years, :currency_precision
  end
end
