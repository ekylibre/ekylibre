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
# == Table: journal_entries
#
#  account_id      :integer          not null
#  comment         :text             
#  company_id      :integer          not null
#  created_at      :datetime         not null
#  creator_id      :integer          
#  credit          :decimal(16, 2)   default(0.0), not null
#  currency_credit :decimal(16, 2)   default(0.0), not null
#  currency_debit  :decimal(16, 2)   default(0.0), not null
#  currency_id     :integer          not null
#  currency_rate   :decimal(16, 6)   not null
#  debit           :decimal(16, 2)   default(0.0), not null
#  draft           :boolean          not null
#  editable        :boolean          default(TRUE)
#  expired_on      :date             
#  id              :integer          not null, primary key
#  intermediate_id :integer          
#  journal_id      :integer          
#  letter          :string(8)        
#  lock_version    :integer          default(0), not null
#  name            :string(255)      not null
#  position        :integer          
#  record_id       :integer          not null
#  statement_id    :integer          
#  updated_at      :datetime         not null
#  updater_id      :integer          
#

class JournalEntry < ActiveRecord::Base
  acts_as_list :scope=>:record
  after_create  :update_record
  after_destroy :update_record
  after_update  :update_record
  attr_readonly :company_id, :record_id, :journal_id
  belongs_to :account
  belongs_to :company
  belongs_to :currency
  belongs_to :journal
  belongs_to :record, :class_name=>JournalRecord.name
  belongs_to :intermediate, :class_name=>BankAccountStatement.name
  belongs_to :statement, :class_name=>BankAccountStatement.name
  validates_presence_of :account_id
  validates_uniqueness_of :letter, :scope=>:account_id, :if=>Proc.new{|x| !x.letter.blank?}
  

  #
  def before_validation 
    # computes the values depending on currency rate
    # for debit and credit.
    self.currency_debit  ||= 0
    self.currency_credit ||= 0
    if self.record
      self.editable = false if self.record.closed?
      self.company_id ||= self.record.company_id 
      self.journal_id ||= self.record.journal_id
    end
    self.currency_id ||= self.journal.currency_id if self.journal
    unless self.currency.nil?
      self.currency_rate = self.currency.rate
      if self.editable 
        self.debit  = self.currency_debit * self.currency_rate 
        self.credit = self.currency_credit * self.currency_rate
      end
    end
  end
  
  #
  def validate
    unless self.editable?
      errors.add_to_base :closed_entry 
      return
    end
    if self.debit.zero? ^ self.credit.zero?
      errors.add(:debit,  :greater_than, :count=>0) if self.debit<=0 and self.credit.zero?
      errors.add(:credit, :greater_than, :count=>0) if self.credit<=0 and self.debit.zero?
    else
      errors.add_to_base :empty_amounts
    end
  end
  
  # this method tests if the entry is locked or not.
  def close?
    return (not self.editable)
  end


  # updates the amounts to the debit and the credit 
  # for the matching record.
  def update_record
    self.record.refresh
  end

  
  # this method allows to lock the entry. 
  def close
    self.update_attribute(:editable, false)
  end
  
  def reopen
    self.update_attribute(:editable, true)
  end
  
  # this method allows to verify if the entry is lettered or not.
  def letter?
    return (not self.letter.blank?)
  end

  #
  def balanced_letter?(letter=nil) 
    letter ||= self.letter
    return false if letter.blank?
    self.account.balanced_letter?(letter)
  end

  #this method allows to fix a display color if the entry is in draft mode.
  def mode
    mode=""
    mode="warning" if self.draft
    mode
  end
  
  #
  def resource
    if self.record
      return self.record.resource_type
    else
      'rien'
    end
  end

  #this method returns the name of journal which the records are saved.
  def journal_name
    if self.record
      return self.record.journal.name
    else
      'rien'
    end
  end
  
  #this method allows to fix a display color if the record containing the entry is balanced or not.
  def balanced_record 
    return (self.record.balanced? ? "balanced" : "unbalanced")
  end

  # this method creates a next entry with an initialized value matching to the previous record. 
  def next(balance)
    entry = JournalEntry.new
    if balance > 0
      entry.currency_credit = balance.abs
    elsif balance < 0
      entry.currency_debit  = balance.abs
    end
    return entry
  end

end

