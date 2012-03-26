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
    execute "UPDATE #{quoted_table_name(:incoming_payment_modes)} SET depositables_journal_id = CASE "+journals.collect{|r| "WHEN cash_id=#{r['id']} THEN #{r['journal_id']}"}.join(" ")+" END WHERE with_deposit"

    add_column :sale_natures, :with_accounting, :boolean, :null=>false, :default=>false
    add_column :sale_natures, :currency, :string, :limit=>3
    add_column :sale_natures, :journal_id, :integer
    sales_journals = connection.select_all("SELECT record_value_id AS id, company_id FROM #{quoted_table_name(:preferences)} WHERE name = 'sales_journal' AND record_value_id IS NOT NULL")
    execute "UPDATE #{quoted_table_name(:sale_natures)} SET with_accounting = #{quoted_true}, currency ='EUR', journal_id=CASE "+sales_journals.collect{|r| "WHEN company_id=#{r['company_id']} THEN #{r['id']}"}.join(" ")+" END"
    sales_journals = connection.select_all("SELECT id, company_id FROM #{quoted_table_name(:journals)} WHERE nature = 'sales' AND currency = 'EUR'")
    execute "UPDATE #{quoted_table_name(:sale_natures)} SET journal_id=CASE "+sales_journals.collect{|r| "WHEN company_id=#{r['company_id']} THEN #{r['id']}"}.join(" ")+" END WHERE journal_id IS NULL"
  end

  def down
    remove_column :sales, :journal_id
    remove_column :sales, :currency
    remove_column :sales, :with_accounting

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
