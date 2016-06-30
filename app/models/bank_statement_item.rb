# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  bank_statement_id  :integer          not null
#  created_at         :datetime         not null
#  creator_id         :integer
#  credit             :decimal(19, 4)   default(0.0), not null
#  currency           :string           not null
#  debit              :decimal(19, 4)   default(0.0), not null
#  id                 :integer          not null, primary key
#  initiated_on       :date
#  letter             :string
#  lock_version       :integer          default(0), not null
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
  has_one :account, through: :cash

  delegate :started_on, :stopped_on, to: :bank_statement

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :initiated_on, :transfered_on, timeliness: { allow_blank: true, on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.today + 50.years }, type: :date }
  validates :credit, :debit, numericality: { allow_nil: true }
  validates :bank_statement, :credit, :currency, :debit, :name, :transfered_on, presence: true
  # ]VALIDATORS]

  before_validation do
    self.currency = bank_statement.currency if bank_statement
    self.debit ||= 0
    self.credit ||= 0
    self.letter = nil if letter.blank?
  end

  validate do
    if (debit != 0 && credit != 0) || (debit == 0 && credit == 0)
      errors.add(:credit, :unvalid_amounts)
    end
    if bank_statement && transfered_on
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

  def associated_journal_entry_items
    return [] unless bank_statement && letter
    JournalEntryItem.pointed_by(bank_statement).where(bank_statement_letter: letter)
  end

  def cash_currency
    bank_statement && bank_statement.cash && bank_statement.cash.currency
  end

  def balance=(new_balance)
    if new_balance > 0
      self.credit = new_balance
    else
      self.debit = - new_balance
    end
  end
end
