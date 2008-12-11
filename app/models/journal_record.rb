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
  acts_as_list :scope=>:period
  
  def before_validation
    self.balanced = (self.debit == self.credit) 
  end
   
   
  def validate
     errors.add_to_base lc(:error_printed_date) if self.printed_on > self.created_on
     if self.period
       errors.add_to_base lc(:error_closed_journal) if self.created_on <= self.period.journal.closed_on 
       errors.add_to_base lc(:error_limited_period) if self.created_on < self.period.started_on or self.created_on > self.period.stopped_on 
     end
   end
  
  # this method computes the debit and the credit of the record.
  def totalize
    #self.update_attributes(:debit=>self.entries.sum(:debit),:credit=>self.entries.sum(:credit))
    #self.debit= Entry.sum(:debit,:conditions=>["record_id = ?", self.id])
    #self.credit= Entry.sum(:credit,:conditions=>["record_id = ?", self.id])
    
    self.debit = self.entries.sum(:debit)
    self.credit = self.entries.sum(:credit)
#    raise Exception.new self.inspect
   # self.balanced = (self.debit == self.credit) 
    self.save(false)
    
  end

  # this method allows to lock the record.
  def close(date)
    self.entries.each do |entrie|
      entrie.close(date)
    end
  end


end
