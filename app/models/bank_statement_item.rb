# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: bank_statement_items
#
#  accounted_at       :datetime
#  bank_statement_id  :integer          not null
#  created_at         :datetime         not null
#  creator_id         :integer
#  credit             :decimal(19, 4)   default(0.0), not null
#  currency           :string           not null
#  debit              :decimal(19, 4)   default(0.0), not null
#  id                 :integer          not null, primary key
#  initiated_on       :date
#  journal_entry_id   :integer
#  letter             :string
#  lock_version       :integer          default(0), not null
#  memo               :string
#  name               :string           not null
#  transaction_number :string
#  transfered_on      :date             not null
#  updated_at         :datetime         not null
#  updater_id         :integer
#
class BankStatementItem < Ekylibre::Record::Base
  refers_to :currency
  belongs_to :bank_statement, inverse_of: :items
  has_one :cash, through: :bank_statement
  has_one :journal, through: :cash
  belongs_to :journal_entry, dependent: :destroy
  delegate :started_on, :stopped_on, to: :bank_statement, allow_nil: true

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :credit, :debit, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :bank_statement, :currency, presence: true
  validates :initiated_on, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }, allow_blank: true
  validates :letter, :memo, :transaction_number, length: { maximum: 500 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :transfered_on, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 100.years }, type: :date }
  # ]VALIDATORS]

  validates :started_on, presence: true, if: :bank_statement
  validates :stopped_on, presence: true, if: :bank_statement

  delegate :name, :currency, :journal, :account, :account_id, :next_reconciliation_letters, to: :cash, prefix: true

  scope :transfered_between, lambda { |period_start, period_end|
    where('transfered_on >= ? AND transfered_on <= ?', period_start, period_end)
  }

  before_validation do
    self.currency = bank_statement.currency if bank_statement
    self.debit ||= 0
    self.credit ||= 0
    self.letter = nil if letter.blank?
  end

  validate do
    if (debit.nonzero? && credit.nonzero?) || (debit.zero? && credit.zero?)
      errors.add(:credit, :unvalid_amounts)
    end
    if bank_statement && transfered_on && started_on && stopped_on
      unless started_on <= transfered_on && transfered_on <= stopped_on
        errors.add(:transfered_on, :invalid)
      end
    end
  end

  before_destroy do
    journal_entry_items = associated_journal_entry_items
    if journal_entry_items.any?
      journal_entry_items.update_all(
        bank_statement_id: nil,
        bank_statement_letter: nil
      )
    end
  end

  bookkeep do |b|
    b.journal_entry(cash_journal, printed_on: transfered_on, if: (cash.enable_bookkeep_bank_item_details && cash.suspend_until_reconciliation)) do |entry|
      entry.add_debit(name, cash.main_account_id, credit_balance, as: :bank)
      entry.add_credit(name, cash.suspense_account_id, credit_balance, as: :suspended, resource: self)
    end
  end

  def associated_journal_entry_items
    return [] unless bank_statement && letter

    JournalEntryItem.where(bank_statement_letter: self.letter, bank_statement_id: self.bank_statement_id)
  end

  def associated_bank_statement_items
    return [] unless bank_statement && letter

    BankStatementItem.where(letter: letter, bank_statement_id: self.bank_statement_id).not.where(id: self.id)
  end

  def cash_currency
    bank_statement && bank_statement.cash && bank_statement.cash.currency
  end

  def balance
    debit - credit
  end

  def credit_balance
    self.credit - self.debit
  end

  def balance=(new_balance)
    if new_balance > 0
      self.credit = new_balance
    else
      self.debit = -new_balance
    end
  end
end
