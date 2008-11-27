# == Schema Information
# Schema version: 20080819191919
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

  def validate
    errors.add lc(:error_period) if self.started_on > self.stopped_on
    journal = Journal.find(self.journal_id)
    errors.add lc(:error_closed_journal) if self.stopped_on > journal.closed_on
    financialyear = Financialyear.find(self.financialyear_id)
    errors.add lc(:error_limited_financialyear) if financialyear.started_on > self.started_on and self.stopped_on > financialyear.stopped_on    
  end

end
