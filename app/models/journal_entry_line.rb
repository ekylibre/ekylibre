# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
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
#  balance           :decimal(16, 2)   default(0.0), not null
#  bank_statement_id :integer          
#  comment           :text             
#  company_id        :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer          
#  credit            :decimal(16, 2)   default(0.0), not null
#  currency_credit   :decimal(16, 2)   default(0.0), not null
#  currency_debit    :decimal(16, 2)   default(0.0), not null
#  debit             :decimal(16, 2)   default(0.0), not null
#  entry_id          :integer          not null
#  id                :integer          not null, primary key
#  journal_id        :integer          
#  letter            :string(8)        
#  lock_version      :integer          default(0), not null
#  name              :string(255)      not null
#  position          :integer          
#  state             :string(32)       default("draft"), not null
#  updated_at        :datetime         not null
#  updater_id        :integer          
#


class JournalEntryLine < CompanyRecord
  acts_as_list :scope=>:entry
  after_create  :update_entry
  after_destroy :update_entry
  after_destroy :unmark
  after_update  :update_entry
  attr_readonly :company_id, :entry_id, :journal_id, :state
  belongs_to :account
  belongs_to :company
  belongs_to :journal
  belongs_to :entry, :class_name=>"JournalEntry"
  belongs_to :bank_statement
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :balance, :credit, :currency_credit, :currency_debit, :debit, :allow_nil => true
  validates_length_of :letter, :allow_nil => true, :maximum => 8
  validates_length_of :state, :allow_nil => true, :maximum => 32
  validates_length_of :name, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  validates_presence_of :account
  # validates_uniqueness_of :letter, :scope=>:account_id, :if=>Proc.new{|x| !x.letter.blank?}


  state_machine :state, :initial=>:draft do
    state :draft
    state :confirmed
    state :closed
  end

  
  #
  before_validation do
    self.name = self.name.to_s[0..254]
    # computes the values depending on currency rate
    # for debit and credit.
    self.currency_debit  ||= 0
    self.currency_credit ||= 0
    currency_rate = nil
    if self.entry
      # self.draft = self.entry.draft
      # self.closed = self.entry.closed
      self.company_id ||= self.entry.company_id 
      self.journal_id ||= self.entry.journal_id
      currency_rate = self.entry.currency.rate
    end
    unless currency_rate.nil?
      unless self.closed?
        self.debit  = self.currency_debit * currency_rate 
        self.credit = self.currency_credit * currency_rate
      end
    end
  end
    
  validate(:on=>:update) do
    old = self.class.find(self.id)
    errors.add_to_base(:entry_has_been_already_validated) if old.closed?
    # Forbids to change "manually" the letter. Use Account#mark/unmark.
    errors.add(:letter, :invalid) if old.letter != self.letter and not (old.balanced_letter? and self.balanced_letter?)
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
  
  protect_on_update do
    not self.closed? and self.entry.updateable?
  end

  protect_on_destroy do
    !self.closed?
  end

  # Prints human name of current state
  def state_label
    ::I18n.t('models.journal_entry.states.'+self.state.to_s)
  end

  # updates the amounts to the debit and the credit 
  # for the matching entry.
  def update_entry
    self.entry.refresh
  end


  # Unmark all the journal entry lines with the same mark in the same account
  def unmark
    self.account.unmark(self.letter) unless self.letter.blank?
  end
  
#   # this method allows to lock the entry_line. 
#   def close
#     self.update_attribute(:closed, true)
#   end
  
#   def reopen
#     self.update_attribute(:closed, false)
#   end

  # Check if the current letter is balanced with all entrty lines with the same letter
  def balanced_letter?
    return true if letter.blank?
    self.account.balanced_letter?(letter)
  end

  #this method allows to fix a display color if the entry_line is in draft mode.
  def mode
    mode=""
    mode+="warning" if self.draft?
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

