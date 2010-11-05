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
# == Table: journal_entry_lines
#
#  account_id        :integer          not null
#  bank_statement_id :integer          
#  closed            :boolean          not null
#  comment           :text             
#  company_id        :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer          
#  credit            :decimal(16, 2)   default(0.0), not null
#  currency_credit   :decimal(16, 2)   default(0.0), not null
#  currency_debit    :decimal(16, 2)   default(0.0), not null
#  debit             :decimal(16, 2)   default(0.0), not null
#  draft             :boolean          not null
#  entry_id          :integer          not null
#  expired_on        :date             
#  id                :integer          not null, primary key
#  journal_id        :integer          
#  letter            :string(8)        
#  lock_version      :integer          default(0), not null
#  name              :string(255)      not null
#  position          :integer          
#  updated_at        :datetime         not null
#  updater_id        :integer          
#


class JournalEntryLine < ActiveRecord::Base
  acts_as_list :scope=>:entry
  after_create  :update_entry
  after_destroy :update_entry
  after_update  :update_entry
  attr_readonly :company_id, :entry_id, :journal_id
  belongs_to :account
  belongs_to :company
  belongs_to :journal
  belongs_to :entry, :class_name=>JournalEntry.name
  belongs_to :bank_statement
  validates_presence_of :account_id
  # validates_uniqueness_of :letter, :scope=>:account_id, :if=>Proc.new{|x| !x.letter.blank?}
  
  #
  before_validation do
    self.name = self.name.to_s[0..254]
    # computes the values depending on currency rate
    # for debit and credit.
    self.currency_debit  ||= 0
    self.currency_credit ||= 0
    currency_rate = nil
    if self.entry
      self.draft = self.entry.draft
      self.closed = self.entry.closed
      self.company_id ||= self.entry.company_id 
      self.journal_id ||= self.entry.journal_id
      currency_rate = self.entry.currency.rate
    end
    unless currency_rate.nil?
      unless self.closed
        self.debit  = self.currency_debit * currency_rate 
        self.credit = self.currency_credit * currency_rate
      end
    end
  end
    
  validate(:on=>:update) do
    old = self.class.find(self.id)
    errors.add_to_base(:entry_has_been_already_validated) if old.closed?
  end

  #
  validate do
    unless self.updateable?
      errors.add_to_base :closed_entry_line 
      return
    end
    errors.add_to_base :unvalid_amounts if self.debit != 0 and self.credit != 0
    errors.add(:debit,  :greater_or_equal_than, :count=>0) if self.debit<0
    errors.add(:credit, :greater_or_equal_than, :count=>0) if self.credit<0
  end
  
  # this method tests if the entry_line is locked or not.
  def close?
    return self.closed?
  end

  protect_on_update do
    not self.closed? and self.entry.updateable?
  end

  protect_on_destroy do
    !self.closed?
  end

  # updates the amounts to the debit and the credit 
  # for the matching entry.
  def update_entry
    self.entry.refresh
  end

  
  # this method allows to lock the entry_line. 
  def close
    self.update_attribute(:closed, true)
  end
  
  def reopen
    self.update_attribute(:closed, false)
  end
  
  # this method allows to verify if the entry_line is lettered or not.
  def letter?
    return (not self.letter.blank?)
  end

  #
  def balanced_letter?(letter=nil) 
    letter ||= self.letter
    return false if letter.blank?
    self.account.balanced_letter?(letter)
  end

  #this method allows to fix a display color if the entry_line is in draft mode.
  def mode
    mode=""
    mode+="warning" if self.draft
    mode
  end
  
  #
  def resource
    if self.entry
      return self.entry.resource_type
    else
      'rien'
    end
  end

  # This method returns the name of journal which the entries are saved.
  def journal_name
    if self.entry
      return self.entry.journal.name
    else
      'rien'
    end
  end
  
  #this method allows to fix a display color if the entry containing the entry_line is balanced or not.
  def balanced_entry 
    return (self.entry.balanced? ? "balanced" : "unbalanced")
  end

  # this method creates a next entry_line with an initialized value matching to the previous entry. 
  def next(balance)
    entry_line = JournalEntryLine.new
    if balance > 0
      entry_line.currency_credit = balance.abs
    elsif balance < 0
      entry_line.currency_debit  = balance.abs
    end
    return entry_line
  end

end

