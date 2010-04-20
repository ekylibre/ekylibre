# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Mérigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: journals
#
#  closed_on      :date             default(CURRENT_DATE), not null
#  code           :string(4)        not null
#  company_id     :integer          not null
#  counterpart_id :integer          
#  created_at     :datetime         not null
#  creator_id     :integer          
#  currency_id    :integer          not null
#  deleted        :boolean          not null
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  name           :string(255)      not null
#  nature         :string(16)       not null
#  updated_at     :datetime         not null
#  updater_id     :integer          
#

class Journal < ActiveRecord::Base
  attr_readonly :company_id
  before_destroy :empty?
  belongs_to :company
  belongs_to :currency
  belongs_to :counterpart, :class_name=>Account.name  
  has_many :bank_accounts
  has_many :entries, :class_name=>JournalEntry.name
  has_many :records, :class_name=>JournalRecord.name
  validates_presence_of :closed_on
  validates_uniqueness_of :code, :scope=>:company_id
  validates_uniqueness_of :name, :scope=>:company_id

  @@natures = [:sale, :purchase, :bank, :renew, :various]

  # this method is called before creation or validation method.
  def before_validation
    self.name = self.nature_label if self.name.blank? and self.nature
    self.currency_id ||= self.company.currencies.find(:first, :order=>:id).id
    if self.closed_on == Date.civil(1970,12,31) 
      if Financialyear.exists?(:company_id=>self.company_id)
        self.closed_on = Financialyear.find(:first, :conditions => {:company_id => self.company_id}).started_on-1 
      else
        self.closed_on = Date.civil(1970,12,31) 
      end
    end
    self.code = tc('natures.'+self.nature.to_s).codeize if self.code.blank?
    self.code = self.code[0..3]
  end

  def validate
    valid = false
    for financialyear in self.company.financialyears
      valid = true if self.closed_on == financialyear.started_on-1
    end
    unless valid
      errors.add(:closed_on, :end_of_month, :closed_on=>::I18n.localize(self.closed_on)) if self.closed_on != self.closed_on.end_of_month
    end
  end


  def destroyable?
    @journal.records.size <= 0 and @journal.entries.size <= 0
  end


  # Provides a translation for the nature of the journal
  def nature_label(nature=nil)
    tc('natures.'+(nature||self.nature).to_s)
  end


  # tests if the record contains entries.
  def empty?
     return self.records.size <= 0
  end

  #
  def balance?
    self.records.each do |record|
      unless record.balanced and record.normalized
        return false 
      end
    end
    return true
  end
  

  #
  def closable?(closed_on=nil)
    closed_on ||= Date.today
    return false unless (closed_on << 1).end_of_month > self.closed_on
    return true
  end

  def closures(noticed_on=nil)
    noticed_on ||= Date.today
    array, date = [], (self.closed_on+1).end_of_month
    while date < noticed_on
      array << date
      date = (date+1).end_of_month
    end
    return array
  end

  # this method closes a journal.
  def close(closed_on)
    errors.add(:closed_on, :end_of_month) if self.closed_on != self.closed_on.end_of_month
    errors.add_to_base(:draft_entries) if self.entries.find(:all, :joins=>"JOIN journal_records ON (record_id=journal_records.id)", :conditions=>["draft=? AND created_on BETWEEN ? AND ? ", true, self.closed_on+1, closed_on ]).size > 0
    return false unless errors.empty?
    ActiveRecord::Base.transaction do
      for record in self.records.find(:all, :conditions=>["created_on BETWEEN ? AND ? ", self.closed_on+1, closed_on])
        record.close
      end
      self.update_attribute(:closed_on, closed_on)
    end
    return true
  end


  def reopenable?
    return false unless self.reopenings.size > 0
    return true
  end

  def reopenings
    year = self.company.current_financialyear
    return [] if year.nil?
    array, date = [], year.started_on-1
    while date < self.closed_on
      array << date
      date = (date+1).end_of_month
    end
    return array
  end

  def reopen(closed_on)
    ActiveRecord::Base.transaction do
      for record in self.records.find(:all, :conditions=>["created_on BETWEEN ? AND ? ", closed_on+1, self.closed_on])
        record.reopen
      end
      self.update_attribute(:closed_on, closed_on)
    end
    return true
  end

  def last_number
    record = self.records.find(:first, :conditions=>["created_on>=?", self.closed_on], :order=>"number DESC")
    return record ? record.number : "000000"
  end




  # this method searches the last records according to a number.  
  def last_records(period, number_record=:all)
    period.records.find(:all, :order => "lpad(number,20,'0') DESC", :limit => number_record)
  end

  # this method returns an array .
  def self.natures
    @@natures.collect{|x| [tc('natures.'+x.to_s), x] }
  end

  def entries_between(started_on, stopped_on)
    self.entries.find(:all, :joins=>"JOIN journal_records ON (journal_records.id=record_id)", :conditions=>["printed_on BETWEEN ? AND ? ", started_on, stopped_on], :order=>"printed_on, journal_records.id, journal_entries.id")
  end

  def entries_calculate(column, started_on, stopped_on, operation=:sum)
    column = (column == :balance ? "currency_debit - currency_credit" : "currency_#{column}")
    self.entries.calculate(operation, column, :joins=>"JOIN journal_records ON (journal_records.id=record_id)", :conditions=>["printed_on BETWEEN ? AND ? ", started_on, stopped_on])
  end

end

