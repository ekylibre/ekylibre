# == Schema Information
# Schema version: 20090512102847
#
# Table name: journals
#
#  id             :integer       not null, primary key
#  nature         :string(16)    not null
#  name           :string(255)   not null
#  code           :string(4)     not null
#  deleted        :boolean       not null
#  currency_id    :integer       not null
#  counterpart_id :integer       
#  closed_on      :date          default(Thu, 31 Dec 1970), not null
#  company_id     :integer       not null
#  created_at     :datetime      not null
#  updated_at     :datetime      not null
#  created_by     :integer       
#  updated_by     :integer       
#  lock_version   :integer       default(0), not null
#

class Journal < ActiveRecord::Base
  belongs_to :company
  belongs_to :currency
  belongs_to :counterpart, :class_name=>"Account"
  
  has_many :bank_accounts
  has_many :records, :class_name=>"JournalRecord", :foreign_key=>:journal_id

  #   before_create :journal_nature
  before_destroy :empty?

  #
  def before_validation
    if self.closed_on.nil?
      self.closed_on = Date.civil(1970,1,1) 
    end
  end

  #
  def validate
  end

  # tests if the record contains entries.
  def empty?
     return self.records.size <= 0
  end

  #
  def closable?(closed_on)
    if closed_on < self.closed_on
      #errors.add_to_base tc(:error_already_closed_journal)
      return false
    else
      self.records.each do |record|
        unless record.balanced
          #errors.add_to_base tc(:error_unbalanced_record_journal)
          return false 
        end
      end
      return true
    end
 end
  
  # this method closes a journal.
  def close(closed_on)
    if self.closable?(closed_on)
      self.update_attribute(:closed_on, closed_on)
      self.records.each do |record|
        record.close
      end
    end
  end
  
  # this method searches the last records according to a number.  
  def last_records(period, number_record=:all)
    period.records.find(:all, :order => "lpad(number,20,'0') DESC", :limit => number_record)
  end

  # this method returns an array .
  def self.natures
    [:sale, :purchase, :bank, :renew, :various].collect{|x| [tc('natures.'+x.to_s), x] }
  end

end

