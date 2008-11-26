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
  
before_create :valide_date

  def valide_date
    journal = Journal.find(self.journal_id)
    raise "This operation can not be realized because the journal is already closed." if self.created_on > journal.closed_on 
    period = JournalPeriod.find(self.period_id)
    financialyear = Financialyear.find(period.financialyear_id) 
    raise "Incompatible period." unless financialyear.started_on < self.created_on and self.created_on < financialyear.stopped_on    
  end

end
