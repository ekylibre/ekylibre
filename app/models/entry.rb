# == Schema Information
# Schema version: 20080819191919
#
# Table name: entries
#
#  id              :integer       not null, primary key
#  record_id       :integer       not null
#  account_id      :integer       not null
#  name            :string(255)   not null
#  currency_id     :integer       not null
#  currency_rate   :decimal(16, 6 default(1.0), not null
#  currency_debit  :decimal(16, 2 default(0.0), not null
#  currency_credit :decimal(16, 2 default(0.0), not null
#  debit           :decimal(16, 2 default(0.0), not null
#  credit          :decimal(16, 2 default(0.0), not null
#  intermediate_id :integer       
#  statement_id    :integer       
#  letter          :string(8)     
#  expired_on      :date          
#  position        :integer       
#  comment         :text          
#  company_id      :integer       not null
#  created_at      :datetime      not null
#  updated_at      :datetime      not null
#  created_by      :integer       
#  updated_by      :integer       
#  lock_version    :integer       default(0), not null
#

class Entry < ActiveRecord::Base
  

before_create :search_currency
after_create  :account_is_debit


  def search_currency()
    currency = Currency.find(:conditions=>["rate = ?", self.currency_rate])
    raise "No currency defined with this rate." unless currency.id 
  end

  # Test if the matching account is debit
  def account_is_debit()
    entries = Entry.find(:all,:conditions=>["account_id = ?", self.account_id])
    entries.each do |entrie|
      debit += entrie.debit
      credit += entrie.credit
    end
    
    account = Account.find(self.account_id)
    account.is_debit = true if (debit > credit)
   
  end



end
