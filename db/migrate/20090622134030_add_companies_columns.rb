class AddCompaniesColumns < ActiveRecord::Migration
  def self.up
    add_column :bank_accounts, :bank_name, :string, :limit=>50

    if (currencies = connection.select_all("SELECT id, company_id FROM #{quote_table_name(:currencies)}")).size > 0
      execute "UPDATE #{quote_table_name(:prices)} SET currency_id=COALESCE(currency_id, CASE "+currencies.collect{|x| "WHEN company_id=#{x['company_id']} THEN #{x['id']}"}.join+" ELSE 0 END)"
    end
  
    add_column :products, :product_account_id, :integer, :references=>:bank_accounts, :on_delete=>:cascade, :on_update=>:cascade
    add_column :products, :charge_account_id,  :integer, :references=>:bank_accounts, :on_delete=>:cascade, :on_update=>:cascade

    for company in connection.select_all("SELECT companies.id AS cid, pa.id AS pa_id, ca.id AS ca_id FROM #{quote_table_name(:companies)} AS companies LEFT JOIN #{quote_table_name(:accounts)} AS pa ON (pa.company_id=companies.id AND pa.number='7') LEFT JOIN #{quote_table_name(:accounts)} AS ca ON (ca.company_id=companies.id AND ca.number='6')")
      pa_id = company['pa_id']
      ca_id = company['ca_id']
      execute "UPDATE #{quote_table_name(:products)} SET updated_at = CURRENT_TIMESTAMP#{', product_account_id='+pa_id.to_s if pa_id}#{', charge_account_id='+ca_id.to_s if ca_id}"
    end
    
    remove_index :products, :column=>:account_id
    remove_column :products, :account_id

    add_column :companies, :sales_journal_id, :integer, :references=>:journals, :on_delete=>:cascade, :on_update=>:cascade
    add_column :companies, :purchases_journal_id,:integer,:references=>:journals,:on_delete=>:cascade, :on_update=>:cascade
    add_column :companies, :bank_journal_id, :integer, :references=>:journals, :on_delete=>:cascade, :on_update=>:cascade

  end
  
  def self.down
    remove_column :companies, :bank_journal_id
    remove_column :companies, :purchases_journal_id
    remove_column :companies, :sales_journal_id
    add_column    :products, :account_id, :integer, :references=>:bank_accounts, :on_delete=>:cascade, :on_update=>:cascade
    remove_column :products, :charge_account_id
    remove_column :products, :product_account_id
    remove_column :bank_accounts, :bank_name
  end
end
