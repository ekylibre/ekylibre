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
after_create  :account_is_debit, :up_record


  # the rate precised must be mentioned in the database.
  def search_currency()
    currency = Currency.find(:conditions=>["rate = ?", self.currency_rate])
    raise "No currency defined with this rate." unless currency.id 
  end

  # tests if the matching account is debit.
  def account_is_debit()
    list_entries_record(:field=>:account_id, :value=>self.account_id)
    account = Account.find(self.account_id)
    account.is_debit = true if (debit > credit)
  end
  

  # updates the amounts to the debit and the credit 
  # for the matching record.
  def up_record()
    list_entries_record(:field=>:record_id, :value=>self.record_id)
    record = JournalRecord.find(self.record_id)
    up_attributes(:instance=>record,
                  :fields=>[:debit, :credit], 
                  :values=>[debit, credit])
#     record.update_attribute(debit, debit)
#     record.update_attribute(credit, credit)

  end
  
  # updates the amounts to the debit and the credit
  # in the balance for the considered account.
  def up_balance()
    list_entries_record(:field=>:account_id, :value=>self.account_id)
    account = AccountBalance.find(account_id)
    up_attributes(:instance=>account,
                  :fields=>[:global_debit,:global_credit,:global_balance, :local_debit, :local_credit, :local_balance],
                  :values=>[debit, credit])
#     account.update_attribute(global_debit, account.global_debit + debit)
#     account.update_attribute(global_credit, account.global_credit + credit)
#     account.update_attribute(global_balance, account.global_balance + (debit - credit))
#     account.update_attribute(local_debit, debit)
#     account.update_attribute(local_credit, credit)
#     account.update_attribute(local_balance, debit - credit)
    
  end
  

  private
  
  # 
  def up_attributes(options={})
    unless options[:instance].blank?
      options[:fields].detect do |field|
        options[:instance].update_attribute(field)
      end
    end
  end


  # lists all the entries matching to a record.
  def list_entries_record(options={})
    entries = Entry.find(:all,:conditions=>["#{options[:field]} = ?", options[:value] ])
    entries.each do |entrie|
      debit += entrie.debit
      credit += entrie.credit
    end
    
  end
  
end
