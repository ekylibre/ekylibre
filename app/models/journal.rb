# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2010 Brice Texier, Thibaud Merigon
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
#  closed_on    :date             default(CURRENT_DATE), not null
#  code         :string(4)        not null
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  currency_id  :integer          not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  nature       :string(16)       not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class Journal < ActiveRecord::Base
  attr_readonly :company_id
  before_destroy :empty?
  belongs_to :company
  belongs_to :currency
  # cattr_accessor :natures
  has_many :cashes
  has_many :entry_lines, :class_name=>JournalEntryLine.name
  has_many :entries, :class_name=>JournalEntry.name
  validates_presence_of :closed_on
  validates_uniqueness_of :code, :scope=>:company_id
  validates_uniqueness_of :name, :scope=>:company_id

  @@natures = [:sales, :purchases, :bank, :forward, :various, :cash]

  # this method is called before creation or validation method.
  def prepare
    self.name = self.nature_label if self.name.blank? and self.nature
    self.currency_id ||= self.company.currencies.find(:first, :order=>:id).id
    if self.closed_on.blank?
      if fy = self.company.financial_years.first
        self.closed_on = fy.started_on-1 
      else
        self.closed_on = Date.civil(1970, 12, 31)
      end
    end
    self.code = tc('natures.'+self.nature.to_s).codeize if self.code.blank?
    self.code = self.code[0..3]
  end

  def check
    valid = false
    for financial_year in self.company.financial_years
      valid = true if self.closed_on == financial_year.started_on-1
    end
    unless valid
      errors.add(:closed_on, :end_of_month, :closed_on=>::I18n.localize(self.closed_on)) if self.closed_on.to_date != self.closed_on.end_of_month.to_date
    end
  end

  def destroyable?
    self.entries.size <= 0 and self.entry_lines.size <= 0 and self.cashes.size <= 0
  end

  # Provides a translation for the nature of the journal
  def nature_label(nature=nil)
    tc('natures.'+(nature||self.nature).to_s)
  end


  # tests if the entry contains entry_lines.
  def empty?
     return self.entries.size <= 0
  end

  #
  def balance?
    self.entries.each do |entry|
      unless entry.balanced and entry.normalized
        return false 
      end
    end
    return true
  end  

  #
  def closable?(closed_on=nil)
    closed_on ||= Date.today
    self.class.update_all({:closed_on=>Date.civil(1900,12,31)}) if self.closed_on.nil?
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
    errors.add_to_base(:draft_entry_lines) if self.entry_lines.find(:all, :joins=>"JOIN #{JournalEntry.table_name} AS journal_entries ON (entry_id=journal_entries.id)", :conditions=>["draft=? AND created_on BETWEEN ? AND ? ", true, self.closed_on+1, closed_on ]).size > 0
    return false unless errors.empty?
    ActiveEntry::Base.transaction do
      for entry in self.entries.find(:all, :conditions=>["created_on BETWEEN ? AND ? ", self.closed_on+1, closed_on])
        entry.close
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
    year = self.company.current_financial_year
    return [] if year.nil?
    array, date = [], year.started_on-1
    while date < self.closed_on
      array << date
      date = (date+1).end_of_month
    end
    return array
  end

  def reopen(closed_on)
    ActiveEntry::Base.transaction do
      for entry in self.entries.find(:all, :conditions=>["created_on BETWEEN ? AND ? ", closed_on+1, self.closed_on])
        entry.reopen
      end
      self.update_attribute(:closed_on, closed_on)
    end
    return true
  end

  def next_number
    entry = self.entries.find(:first, :conditions=>["created_on>=?", self.closed_on], :order=>"number DESC")
    code = entry ? entry.number : self.code.to_s+"000000"
    code.gsub!(/(9+)$/, '0\1') if code.match(/[^\d]9+$/)
    return code.succ
  end



  # this method searches the last entries according to a number.  
  def last_entries(period, number_entry=:all)
    period.entries.find(:all, :order => "lpad(number,20,'0') DESC", :limit => number_entry)
  end

  # this method returns an array .
  def self.natures
    @@natures.collect{|x| [tc('natures.'+x.to_s), x] }
  end

  def entry_lines_between(started_on, stopped_on)
    self.entry_lines.find(:all, :joins=>"JOIN #{JournalEntry.table_name} AS journal_entries ON (journal_entries.id=entry_id)", :conditions=>["printed_on BETWEEN ? AND ? ", started_on, stopped_on], :order=>"printed_on, journal_entries.id, journal_entry_lines.id")
  end

  def entry_lines_calculate(column, started_on, stopped_on, operation=:sum)
    column = (column == :balance ? "currency_debit - currency_credit" : "currency_#{column}")
    self.entry_lines.calculate(operation, column, :joins=>"JOIN #{JournalEntry.table_name} AS journal_entries ON (journal_entries.id=entry_id)", :conditions=>["printed_on BETWEEN ? AND ? ", started_on, stopped_on])
  end

end

