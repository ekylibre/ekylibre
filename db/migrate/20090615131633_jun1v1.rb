class Jun1v1 < ActiveRecord::Migration
  def self.up
    add_column :bank_accounts, :default, :boolean, :null => false, :default => false

    Entity.find_all_by_id(BankAccount.all.collect{|b| b.entity_id}).each do |entity|
      bank_account = entity.bank_accounts.find(:first, :order=>:id)
      bank_account.update_attribute(:default, true) if bank_account
    end
  end

  def self.down
    remove_column :bank_accounts, :default
  end

end
