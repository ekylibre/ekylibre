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
 
   
  after_destroy :update_record
  after_create  :update_record
  
  def before_validation 
    errors.add lc(:error_amount_balance1) unless self.debit.zero? ^ self.credit.zero?     
    errors.add lc(:error_amount_balance2) unless self.debit + self.credit > 0    
    
    # computes the values dependings on currency rate
    # for debit and credit.
    if self.currency.rate.eql?  self.currency_rate
      self.update_attributes(:currency_debit => self.debit * self.currency_rate,
                             :currency_credit => self.credit * self.currency_rate
                             )
    else
      errors.add lc(:error_amount_rate) 
    end
    
  
  end
  
   
  # updates the amounts to the debit and the credit 
  # for the matching record.
  def update_record()
    self.journal_record.totalize
  end
  
  
  
end
