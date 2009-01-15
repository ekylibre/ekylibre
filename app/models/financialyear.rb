# == Schema Information
# Schema version: 20081127140043
#
# Table name: financialyears
#
#  id           :integer       not null, primary key
#  code         :string(12)    not null
#  closed       :boolean       not null
#  started_on   :date          not null
#  stopped_on   :date          not null
#  written_on   :date          
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Financialyear < ActiveRecord::Base
  #validates_uniqueness_of [:started_on, :stopped_on]


  def before_validation
    #self.code = name.to_s[0..7].simpleize if code.blank?
    #self.code = rand.to_s[2..100].to_i.to_s(36)[0..7] if code.blank?
    self.stopped_on = self.stopped_on.end_of_month unless self.stopped_on.blank?
    self.code.upper!
    while Financialyear.count(:conditions=>["code=? AND id!=?",self.code, self.id]) > 0 do
      self.code.succ!
    end
    
  end

  #
  def validate
   # errors.add_to_base lc(:error_stopped1_financialyear)  f self.stopped_on.nil?
    unless self.stopped_on.blank? 
      errors.add_to_base lc(:error_stopped2_financialyear) unless self.stopped_on == self.stopped_on.end_of_month
      errors.add_to_base lc(:error_period_financialyear)  if self.started_on >= self.stopped_on
    end
 #   puts "p"+self.started_on.to_s+self.stopped_on.to_s+self.company_id.to_s
    financial_start = Financialyear.find(:all, :conditions => "company_id = #{self.company_id} AND '#{self.started_on}' BETWEEN started_on AND stopped_on")
    financial_stop = Financialyear.find(:all, :conditions => "company_id = #{self.company_id} AND '#{self.stopped_on}' BETWEEN started_on AND stopped_on")
    puts 'financial:'+financial_start.inspect+financial_stop.inspect
    errors.add_to_base lc(:error_overlap_financialyear) if financial_start.size > 0 or financial_stop.size > 0
  end
  
  # When a financial year is closed, all the matching journals are closed too. 
  def close(date)
    self.update_attributes(:stopped_on => date, :closed => true)
    periods = JournalPeriod.find_all_by_financialyear_id(self.id)
   
    if periods.size > 0
      periods.each do |period|
        period.journal.close(date)
      end
    end
  end
  
end
