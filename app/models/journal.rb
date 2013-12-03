# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Mérigon
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
  belongs_to :company
  belongs_to :currency
  belongs_to :counterpart, :class_name=>"Account"
  
  has_many :bank_accounts
  has_many :records, :class_name=>"JournalRecord", :foreign_key=>:journal_id
  has_many :entries, :through=>:records
  validates_presence_of :closed_on

  before_destroy :empty?

  @@natures = [:sale, :purchase, :bank, :renew, :various]

  # this method is called before creation or validation method.
  def before_validation
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


  # Provides a translation for the nature of the journal
  def nature_label
    tc('natures.'+self.nature.to_s)
  end


  # tests if the record contains entries.
  def empty?
     return self.records.size <= 0
  end

  #
  def closable?(closed_on)
    if closed_on < self.closed_on #or
      #errors.add_to_base tc(:error_already_closed_journal)
      return false
    else
      return self.balance?
    end
 end

  #
  def balance?
    self.records.each do |record|
      unless record.balanced and record.normalized
        #errors.add_to_base tc(:error_unbalanced_record_journal)
        return false 
      end
    end
    return true
  end

  
  # this method closes a journal.
  def close(closed_on)
    #if self.closable?(closed_on)
      self.update_attribute(:closed_on, closed_on)
      self.records.each do |record|
        record.close
      end
    #end
  end
  
  # this method searches the last records according to a number.  
  def last_records(period, number_record=:all)
    period.records.find(:all, :order => "lpad(number,20,'0') DESC", :limit => number_record)
  end

  # this method returns an array .
  def self.natures
    @@natures.collect{|x| [tc('natures.'+x.to_s), x] }
  end

end

