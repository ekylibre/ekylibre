# == Schema Information
# Schema version: 20081127140043
#
# Table name: journal_periods
#
#  id               :integer       not null, primary key
#  journal_id       :integer       not null
#  financialyear_id :integer       not null
#  started_on       :date          not null
#  stopped_on       :date          not null
#  closed           :boolean       
#  debit            :decimal(16, 2 default(0.0), not null
#  credit           :decimal(16, 2 default(0.0), not null
#  balance          :decimal(16, 2 default(0.0), not null
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  updated_at       :datetime      not null
#  created_by       :integer       
#  updated_by       :integer       
#  lock_version     :integer       default(0), not null
#


class JournalPeriod < ActiveRecord::Base
  validates_uniqueness_of [:started_on, :stopped_on], 
                          :scope=> :journal_id

  def before_validation
    puts 'd1:'+self.financialyear.inspect
    self.financialyear = Financialyear.find(:first, :conditions=>['company_id = ? AND ? BETWEEN started_on AND stopped_on',self.company_id, self.started_on ]) if self.started_on and !self.financialyear
    if self.financialyear and self.started_on
      self.started_on = self.financialyear.started_on if self.started_on.month == self.financialyear.started_on.month 
      self.started_on = self.started_on.beginning_of_month if self.started_on.month != self.financialyear.started_on.month and self.started_on!=self.started_on.beginning_of_month
      self.stopped_on = self.started_on.end_of_month
    end
  end



  def validate
    puts 'd:'+self.financialyear.inspect
    puts 'f:'+self.started_on.to_s
    errors.add lc(:error_period) if self.started_on > self.stopped_on
    errors.add lc(:error_period) if self.started_on != self.financialyear.started_on and self.started_on!=self.started_on.beginning_of_month
    
    if self.journal 
      errors.add lc(:error_closed_journal) if self.started_on <= self.journal.closed_on
    end
    
    if self.financialyear
      errors.add lc(:error_closed_financialyear) if self.financialyear.closed
      errors.add lc(:error_limited_financialyear) if self.financialyear.started_on > self.started_on or self.financialyear.stopped_on < self.stopped_on
    end
  end
  
  
  def close(date)
    self.update_attributes(:stopped_on => date, :closed => true)
    self.journal_records.each do |record|
      record.close(date)
    end
    
  end    
  
end
