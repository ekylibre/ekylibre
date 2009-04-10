# == Schema Information
# Schema version: 20090407073247
#
# Table name: financialyears
#
#  id           :integer       not null, primary key
#  code         :string(12)    not null
#  closed       :boolean       not null
#  started_on   :date          not null
#  stopped_on   :date          not null
#  written_on   :date          not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Financialyear < ActiveRecord::Base
  belongs_to :company

  has_many :account_balances, :class_name=>"AccountBalance", :foreign_key=>:financialyear_id

  has_many :periods,  :class_name=>"JournalPeriod", :foreign_key=>:financialyear_id

  #
  def before_validation
    self.stopped_on = self.stopped_on.end_of_month unless self.stopped_on.blank?
    self.code.upper!
    while Financialyear.count(:conditions=>["code=? AND id!=?",self.code, self.id]) > 0 do
      self.code.succ!
    end
    
  end

  #
  def validate
    unless self.stopped_on.blank? 
      errors.add_to_base lc(:error_stopped2_financialyear) unless self.stopped_on == self.stopped_on.end_of_month
      errors.add_to_base lc(:error_period_financialyear) unless self.started_on < self.stopped_on
    end
 
    errors.add_to_base lc(:error_written_financialyear) unless self.written_on >= self.stopped_on
  end
  
  # When a financial year is closed, all the matching journals are closed too. 
  def close(date)
    periods = self.periods 
    
    if periods.size > 0
      periods.each do |period|
         unless period.closed
           errors.add_to_base lc(:error_unclosed_period_financialyear)
           return false
         end
      end
    end
    self.update_attributes(:stopped_on => date, :closed => true)
    return true
  end
  
end
