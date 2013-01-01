# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: bank_statements
#
#  cash_id      :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  credit       :decimal(19, 4)   default(0.0), not null
#  debit        :decimal(19, 4)   default(0.0), not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  number       :string(255)      not null
#  started_on   :date             not null
#  stopped_on   :date             not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class BankStatement < CompanyRecord
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :credit, :debit, :allow_nil => true
  validates_length_of :number, :allow_nil => true, :maximum => 255
  validates_presence_of :cash, :credit, :debit, :number, :started_on, :stopped_on
  #]VALIDATORS]
  belongs_to :cash
  has_many :lines, :dependent=>:nullify, :class_name=>"JournalEntryLine"

  before_validation do
    self.debit  = self.lines.sum(:original_debit)
    self.credit = self.lines.sum(:original_credit)
  end

  # A bank account statement has to contain all the planned records.
  validate do
    errors.add(:stopped_on, :posterior, :to=>::I18n.localize(self.started_on)) if self.started_on >= self.stopped_on
  end

  def balance_credit
    return (self.debit > self.credit ? 0.0 : self.credit-self.debit)
  end

  def balance_debit
    return (self.debit > self.credit ? self.debit-self.credit : 0.0)
  end

  def previous
    self.class.find(:first, :conditions=>{:stopped_on=>self.started_on-1})
  end

  def next
    self.class.find(:first, :conditions=>{:started_on=>self.stopped_on+1})
  end

  def eligible_lines
    JournalEntryLine.where("bank_statement_id = ? OR (account_id = ? AND (bank_statement_id IS NULL OR journal_entries.created_on BETWEEN ? AND ?))", self.id, self.cash.account_id, self.started_on, self.stopped_on).joins("INNER JOIN #{JournalEntry.table_name} AS journal_entries ON journal_entries.id = entry_id").order("bank_statement_id DESC, #{JournalEntry.table_name}.printed_on DESC, #{JournalEntryLine.table_name}.position")
  end

end
