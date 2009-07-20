# == Schema Information
#
# Table name: financialyears
#
#  id           :integer       not null, primary key
#  code         :string(12)    not null
#  closed       :boolean       not null
#  started_on   :date          not null
#  stopped_on   :date          not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  lock_version :integer       default(0), not null
#  creator_id   :integer       
#  updater_id   :integer       
#

class Financialyear < ActiveRecord::Base
  belongs_to :company

  has_many :account_balances, :class_name=>"AccountBalance", :foreign_key=>:financialyear_id

  has_many :records,  :class_name=>"JournalRecord"

  #
  def before_validation
    self.stopped_on = self.started_on+1.year if self.stopped_on.blank? and self.started_on
    self.stopped_on = self.stopped_on.end_of_month unless self.stopped_on.blank?
    if self.started_on
      self.code = self.started_on.year.to_s
      self.code += "/"+self.stopped_on.year.to_s if self.started_on.year!=self.stopped_on.year
      self.code += "EX"
    end
    self.code.upper!
    if self.company
      while self.company.financialyears.count(:conditions=>["code=? AND id!=?",self.code, self.id||0]) > 0 do
        self.code.succ!
      end
    end
  end

  #
  def validate
    unless self.stopped_on.blank? 
      errors.add_to_base lc(:error_stopped2_financialyear) unless self.stopped_on == self.stopped_on.end_of_month
      errors.add_to_base lc(:error_period_financialyear) unless self.started_on < self.stopped_on
    end
  
  end
  
  # tests if the financialyear can be closed.
  def closable?
    records = self.records
    if records.size > 0
      records.each do |record|
        return false unless record.balanced
        #   return false unless record.closed
      end
    end
    return true
    #else
    #  return false
  end

    # When a financial year is closed, all the matching journals are closed too. 
  def close(date)
    if self.closable?
      self.company.journals.find(:all, :conditions => ["closed_on < ?", date]).each do |journal|
        journal.close(date)
      end
      self.update_attributes(:stopped_on => date, :closed => true)
    end
  end

  # this method returns the previous financialyear.
  def previous(company)
    return Financialyear.find(:last, :conditions => ["company_id = ? AND stopped_on < ?", company, self.started_on], :order => "stopped_on ASC")
  end
 
   # this method returns the next financialyear.
  def next(company)
    return Financialyear.find(:first, :conditions => ["company_id = ? AND started_on = ?", company, self.stopped_on+1], :order => "started_on ASC")
  end
 
 
end
