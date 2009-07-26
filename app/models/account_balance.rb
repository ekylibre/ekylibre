# == Schema Information
#
# Table name: account_balances
#
#  account_id       :integer       not null
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  creator_id       :integer       
#  financialyear_id :integer       not null
#  global_balance   :decimal(16, 2 default(0.0), not null
#  global_count     :integer       default(0), not null
#  global_credit    :decimal(16, 2 default(0.0), not null
#  global_debit     :decimal(16, 2 default(0.0), not null
#  id               :integer       not null, primary key
#  local_balance    :decimal(16, 2 default(0.0), not null
#  local_count      :integer       default(0), not null
#  local_credit     :decimal(16, 2 default(0.0), not null
#  local_debit      :decimal(16, 2 default(0.0), not null
#  lock_version     :integer       default(0), not null
#  updated_at       :datetime      not null
#  updater_id       :integer       
#

class AccountBalance < ActiveRecord::Base
  belongs_to :account
  belongs_to :company
  belongs_to :financialyear
  
  # validates_uniqueness_of :account, :name, :label 



   #lists the accounts used in a given period with the credit and the debit.
   def self.balance(period)
     accounts = self.find(:all, :conditions=>{:financialyear_id=>period})
     
     unless accounts.empty?
       results = Hash.new
       
       accounts.each do |account|
         
         results[account.id] = Hash.new
         detail_account = Account.find(account.id)
         
         results[account.id][:number] = detail_account.number
         results[account.id][:name] = detail_account.name
         results[account.id][:debit] = account.local_debit
         results[account.id][:credit] = account.local_credit
         results[account.id][:total_debit] = account.global_debit
         results[account.id][:global_credit] = account.global_credit
       end
       results
     end
     
   end

   
end
