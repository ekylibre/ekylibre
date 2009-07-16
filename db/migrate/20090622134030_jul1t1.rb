class Jul1t1 < ActiveRecord::Migration
  def self.up
    add_column :bank_accounts, :bank_name, :string, :limit=>50
    Price.find(:all).each do |price|
      if price.currency_id.nil?
        price.currency_id = Currency.find(:first, :conditions=>{:company_id=>price.company_id}).id
        price.save
      end
    end
    puts "ok"
  
    add_column :products, :product_account_id, :integer, :references=>:bank_accounts, :on_delete=>:cascade, :on_update=>:cascade
    add_column :products, :charge_account_id,  :integer, :references=>:bank_accounts, :on_delete=>:cascade, :on_update=>:cascade
    
    Product.find(:all).each do |product|
      product_account = Account.find(:first, :conditions=>['deleted=false AND number=?','7'])
      charge_account = Account.find(:first, :conditions=>['deleted=false AND number=? ','6'])
    
      product.product_account_id = product_account.id if product.product_account_id.nil?
      product.charge_account_id = charge_account.id if product.charge_account_id.nil?
      product.save
      # puts product_account.inspect
    end
    
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
