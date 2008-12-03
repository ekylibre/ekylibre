# == Schema Information
# Schema version: 20080819191919
#
# Table name: financialyears
#
#  id           :integer       not null, primary key
#  code         :string(12)    not null
#  nature_id    :integer       not null
#  closed       :boolean       not null
#  started_on   :date          not null
#  stopped_on   :date          not null
#  written_on   :date          not null
#  debit        :decimal(16, 2 default(0.0), not null
#  credit       :decimal(16, 2 default(0.0), not null
#  position     :integer       not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Financialyear < ActiveRecord::Base
  acts_as_list :scope=>:nature
  validates_uniqueness_of [:started_on, :stopped_on]
  
  def validate
    errors.add lc(:error_period_financialyear) if self.started_on > self.stopped_on
    period = JournalPeriod.find_by_stopped_on(:first, :order=>"DESC")  
    errors.add lc(:error_financialyear) if self.started_on < period.stopped_on 
  end
  
# When a financial year is closed, all the matching journals are closed too. 
  def close(date)
    self.update_attributes(:stopped_on => date, :closed => true)
    periods = JournalPeriod.find(:all, :conditions=>{:financialyear_id => self.id})
    periods.each do |period|
      period.journal.close(date)
    end
  end

  
end
