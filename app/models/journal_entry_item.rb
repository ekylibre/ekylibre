# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: journal_entry_items
#
#  absolute_credit           :decimal(19, 4)   default(0.0), not null
#  absolute_currency         :string(3)        not null
#  absolute_debit            :decimal(19, 4)   default(0.0), not null
#  account_id                :integer          not null
#  balance                   :decimal(19, 4)   default(0.0), not null
#  bank_statement_id         :integer
#  created_at                :datetime         not null
#  creator_id                :integer
#  credit                    :decimal(19, 4)   default(0.0), not null
#  cumulated_absolute_credit :decimal(19, 4)   default(0.0), not null
#  cumulated_absolute_debit  :decimal(19, 4)   default(0.0), not null
#  currency                  :string(3)        not null
#  debit                     :decimal(19, 4)   default(0.0), not null
#  description               :text
#  entry_id                  :integer          not null
#  entry_number              :string(255)      not null
#  financial_year_id         :integer          not null
#  id                        :integer          not null, primary key
#  journal_id                :integer          not null
#  letter                    :string(10)
#  lock_version              :integer          default(0), not null
#  name                      :string(255)      not null
#  position                  :integer
#  printed_at                :datetime         not null
#  real_credit               :decimal(19, 4)   default(0.0), not null
#  real_currency             :string(3)        not null
#  real_currency_rate        :decimal(19, 10)  default(0.0), not null
#  real_debit                :decimal(19, 4)   default(0.0), not null
#  state                     :string(30)       not null
#  updated_at                :datetime         not null
#  updater_id                :integer
#

# What are the differents columns:
#   * (credit|debit|balance) are in currency of the journal
#   * real_(credit|debit|balance) are in currency of the financial year
#   * absolute_(credit|debit|balance) are in currency of the company
#   * cumulated_absolute_(credit|debit)are in currency of the company too
class JournalEntryItem < Ekylibre::Record::Base
  attr_readonly :entry_id, :journal_id, :state
  belongs_to :account
  belongs_to :financial_year
  belongs_to :journal, inverse_of: :entry_items
  belongs_to :entry, class_name: "JournalEntry", inverse_of: :items
  belongs_to :bank_statement
  has_many :distributions, class_name: "AnalyticDistribution", foreign_key: :journal_entry_item_id
  # delegate :real_currency, to: :entry

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :absolute_credit, :absolute_debit, :balance, :credit, :cumulated_absolute_credit, :cumulated_absolute_debit, :debit, :real_credit, :real_currency_rate, :real_debit, allow_nil: true
  validates_length_of :absolute_currency, :currency, :real_currency, allow_nil: true, maximum: 3
  validates_length_of :letter, allow_nil: true, maximum: 10
  validates_length_of :state, allow_nil: true, maximum: 30
  validates_length_of :entry_number, :name, allow_nil: true, maximum: 255
  validates_presence_of :absolute_credit, :absolute_currency, :absolute_debit, :account, :balance, :credit, :cumulated_absolute_credit, :cumulated_absolute_debit, :currency, :debit, :entry, :entry_number, :financial_year, :journal, :name, :printed_at, :real_credit, :real_currency, :real_currency_rate, :real_debit, :state
  #]VALIDATORS]
  validates_numericality_of :debit, :credit, :real_debit, :real_credit, :greater_than_or_equal_to => 0
  validates_presence_of :account
  # validates_uniqueness_of :letter, :scope => :account_id, if: Proc.new{|x| !x.letter.blank?}

  acts_as_list :scope => :entry

  before_update  :uncumulate
  before_destroy :uncumulate
  after_create  :update_entry
  after_destroy :update_entry
  after_destroy :unmark
  after_update  :update_entry

  scope :between, lambda { |started_at, stopped_at|
    where(printed_at: started_at..stopped_at)
  }
  state_machine :state, :initial => :draft do
    state :draft
    state :confirmed
    state :closed
  end

  #
  before_validation do
    self.name = self.name.to_s[0..254]
    # computes the values depending on currency rate
    # for debit and credit.
    self.real_debit  ||= 0
    self.real_credit ||= 0
    if self.entry
      self.entry_number = self.entry.number
      for replicated in [:financial_year_id, :printed_at, :journal_id, :state, :currency, :absolute_currency, :real_currency, :real_currency_rate]
        self.send("#{replicated}=", self.entry.send(replicated))
      end
      unless self.closed?
        self.debit  = self.entry.real_currency.to_currency.round(self.real_debit * self.real_currency_rate)
        self.credit = self.entry.real_currency.to_currency.round(self.real_credit * self.real_currency_rate)
      end
    end

    self.absolute_currency ||= self.currency
    if self.absolute_currency == self.currency
      self.absolute_debit = self.real_debit
      self.absolute_credit = self.real_credit
    end
    self.cumulated_absolute_debit  = self.absolute_debit
    self.cumulated_absolute_credit = self.absolute_credit
    if previous = self.previous
      self.cumulated_absolute_debit  += previous.cumulated_absolute_debit
      self.cumulated_absolute_credit += previous.cumulated_absolute_credit
    end
  end

  validate(on: :update) do
    old = self.class.find(self.id)
    errors.add(:account_id, :entry_has_been_already_validated) if old.closed?
    # Forbids to change "manually" the letter. Use Account#mark/unmark.
    errors.add(:letter, :invalid) if old.letter != self.letter and not (old.balanced_letter? and self.balanced_letter?)
  end

  #
  validate do
    # unless self.updateable?
    #   errors.add(:number, :closed_entry)
    #   return
    # end
    errors.add(:credit, :unvalid_amounts) if self.debit != 0 and self.credit != 0
  end

  after_save do
    self.followings.update_all("cumulated_absolute_debit = cumulated_absolute_debit + #{self.absolute_debit}, cumulated_absolute_credit = cumulated_absolute_credit + #{self.absolute_credit}")
  end

  protect do
    self.closed? or (self.entry and self.entry.protected_on_update?)
  end

  # Prints human name of current state
  def state_label
    ::I18n.t('models.journal_entry.states.'+self.state.to_s)
  end

  # Updates the amounts to the debit and the credit
  # for the matching entry.
  def update_entry
    self.entry.refresh
  end

  # Cancel old values if specific columns have been updated
  def uncumulate
    old = self.old_record
    if self.absolute_debit != old.absolute_debit or self.absolute_credit != old.absolute_credit or self.printed_at != old.printed_at
      # self.cumulated_absolute_debit  -= old.absolute_debit
      # self.cumulated_absolute_credit -= old.absolute_credit
      old.followings.update_all("cumulated_absolute_debit = cumulated_absolute_debit - #{old.absolute_debit.to_s}, cumulated_absolute_credit = cumulated_absolute_credit - #{old.absolute_debit}")
    end
  end

  # Unmark all the journal entry items with the same mark in the same account
  def unmark
    self.account.unmark(self.letter) unless self.letter.blank?
  end


  # Returns the previous item
  def previous
    if self.new_record?
      self.account.journal_entry_items.order("printed_at, id").where("printed_at <= ?", self.printed_at).last
    else
      self.account.journal_entry_items.order("printed_at, id").where("(printed_at = ? AND id < ?) OR printed_at <= ?", self.printed_at, self.id, self.printed_at).last
    end
  end


  # Returns following items
  def followings
    if self.new_record?
      self.account.journal_entry_items.where("printed_at > ?", self.printed_at)
    else
      self.account.journal_entry_items.where("(printed_at = ? AND id > ?) OR printed_at > ?", self.printed_at, self.id, self.printed_at)
    end
  end

  # Returns the balance as cumulated_absolute_debit - cumulated_absolute_credit
  def cumulated_absolute_balance
    return (self.cumulated_absolute_debit - self.cumulated_absolute_credit)
  end


#   # this method allows to lock the entry_item.
#   def close
#     self.update_column(:closed, true)
#   end

#   def reopen
#     self.update_column(:closed, false)
#   end

  # Check if the current letter is balanced with all entry items with the same letter
  def balanced_letter?
    return true if letter.blank?
    self.account.balanced_letter?(letter)
  end

  #this method allows to fix a display color if the entry_item is in draft mode.
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

  #this method:allows to fix a display color if the entry containing the entry_item is balanced or not.
  def balanced_entry
    return (self.entry.balanced? ? "balanced" : "unbalanced")
  end

  # this method creates a next entry_item with an initialized value matching to the previous entry.
  def next(balance)
    entry_item = JournalEntryItem.new
    if balance > 0
      entry_item.real_credit = balance.abs
    elsif balance < 0
      entry_item.real_debit  = balance.abs
    end
    return entry_item
  end

end

