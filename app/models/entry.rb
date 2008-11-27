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
  
  before_validation :currency_rate, :debit, :credit
  #before_destroy :
  before_destroy :update_record
  after_create  :update_record
  

  # updates the amounts to the debit and the credit 
  # for the matching record and for the bankaccountstatement.
  def update_record()
    self.journalrecord.totalize
    bank_account = BankAccountStatement.find(self.entry_id)
    bank_account.debit =
    bank_account.credit = 
    bank_account.update_attributes(:debit=>self.debit, :credit=>self.credit) if bank_account.exists? 
  end
  
  private
  
  # lists all the entries matching to a record.
  def list_entries_record(options={})
    entries = Entry.find(:all,:conditions=>{options[:field].to_sym => options[:value]})
    entries.each do |entrie|
      debit += entrie.debit
      credit += entrie.credit
    end
    
  end
  
end
