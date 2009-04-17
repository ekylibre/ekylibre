# == Schema Information
# Schema version: 20090410102120
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
  belongs_to :company
  belongs_to :financialyear
  belongs_to :journal
  has_many :records, :class_name=>"JournalRecord", :foreign_key=>:period_id
  
 
  #
  def before_validation
    self.financialyear = self.company.financialyears.find(:first, :conditions=>['? BETWEEN started_on AND written_on', self.started_on ], :order=>:started_on) if self.started_on and self.company and !self.financialyear
    if self.started_on and self.financialyear
      unless self.out_of_range?
        self.started_on = self.financialyear.started_on if self.started_on.month == self.financialyear.started_on.month 
        self.started_on = self.started_on.beginning_of_month if self.started_on.month != self.financialyear.started_on.month and self.started_on!=self.started_on.beginning_of_month
        self.stopped_on = self.started_on.end_of_month
      end
    end
  end
  
  def validate
    errors.add(:started_on, tc(:error_out_of_range, :started_on=>self.financialyear.started_on.to_s, :stopped_on=>self.financialyear.stopped_on.to_s)) if self.out_of_range?
  end

  def out_of_range?(made_on=nil)
    made_on ||= self.started_on
    not (self.financialyear.started_on<=made_on and made_on<=self.financialyear.written_on)
  end
  #
  def balanced
    self.records.each do |record|
      return false unless record.balanced
    end
    return true
  end
  
  #
  def close(date)
    self.update_attributes(:stopped_on => date, :closed => true) 
    self.records.each do |record|
      record.close
    end
    
  end    
  
end
