# == Schema Information
# Schema version: 20080819191919
#
# Table name: journal_records
#
#  id            :integer       not null, primary key
#  resource_id   :integer       not null
#  resource_type :string(255)   
#  created_on    :date          not null
#  printed_on    :date          not null
#  number        :string(255)   not null
#  status        :string(1)     default("A"), not null
#  debit         :decimal(16, 2 default(0.0), not null
#  credit        :decimal(16, 2 default(0.0), not null
#  balance       :decimal(16, 2 default(0.0), not null
#  position      :integer       not null
#  period_id     :integer       not null
#  journal_id    :integer       not null
#  company_id    :integer       not null
#  created_at    :datetime      not null
#  updated_at    :datetime      not null
#  created_by    :integer       
#  updated_by    :integer       
#  lock_version  :integer       default(0), not null
#

class JournalRecord < ActiveRecord::Base
  


  def validate
    errors.add lc(:error_printed_date) if self.printed_on < self.created_on
    errors.add lc(:error_closed_journal) if self.created_on > self.journal_period.journal.closed_on 
    errors.add lc(:error_limited_period) if self.created_on < self.period.started_on or self.created_on > self.period.stopped_on 
   
    self.started_on.upto(self.stopped_on) do |date|
      if [self.financialyear.started_on, self.financialyear.stopped_on].include? date
        errors.add lc(:error_limited_financialyear) 
      end
    end
    
  end
  

  def totalize
    debit = Entry.sum(:debit, :conditions => {:record_id => self.record_id})
    credit = Entry.sum(:credit, :conditions => {:record_id => self.record_id})
    self.update_attributes(:debit => debit, :credit => credit)
  end
end
