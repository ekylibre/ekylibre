class Jun1v1 < ActiveRecord::Migration
  def self.up
    add_column :bank_accounts, :default, :boolean, :null => false, :default => false

    Entity.find(:all).each do |entity|
      bank_account = entity.bank_accounts.find :first
      bank_account.update_attribute(:default, true) if bank_account
    end

end

  def self.down
    
    BankAccount.find(:all).each do |bank_account|
      bank_account.update_attribute(:default, false) 
    end
    
    remove_column :bank_accounts, :default

  end

end
