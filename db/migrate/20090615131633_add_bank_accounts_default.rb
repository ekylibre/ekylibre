class AddBankAccountsDefault < ActiveRecord::Migration
  def self.up
    add_column :bank_accounts, :default, :boolean, :null => false, :default => false

    execute "UPDATE bank_accounts SET \"default\"=#{quoted_true}"

#     for entity in Entity.find_all_by_id(select_all("SELECT * FROM bank_accounts").collect{|b| b['entity_id'].to_i})
#       bank_account = entity.bank_accounts.find(:first, :order=>:id)
#       bank_account.update_attribute(:default, true) if bank_account
#     end
  end

  def self.down
    remove_column :bank_accounts, :default
  end

end
