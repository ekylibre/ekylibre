# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
# == Table: cash_transfers
#
#  accounted_at               :datetime
#  created_at                 :datetime         not null
#  creator_id                 :integer
#  currency_rate              :decimal(19, 10)  not null
#  description                :text
#  emission_amount            :decimal(19, 4)   not null
#  emission_cash_id           :integer          not null
#  emission_currency          :string           not null
#  emission_journal_entry_id  :integer
#  id                         :integer          not null, primary key
#  lock_version               :integer          default(0), not null
#  number                     :string           not null
#  reception_amount           :decimal(19, 4)   not null
#  reception_cash_id          :integer          not null
#  reception_currency         :string           not null
#  reception_journal_entry_id :integer
#  transfered_at              :datetime         not null
#  updated_at                 :datetime         not null
#  updater_id                 :integer
#

class CashTransfer < Ekylibre::Record::Base
  acts_as_numbered
  attr_readonly :number
  belongs_to :emission_cash, class_name: 'Cash'
  belongs_to :emission_journal_entry, class_name: 'JournalEntry'
  belongs_to :reception_cash, class_name: 'Cash'
  belongs_to :reception_journal_entry, class_name: 'JournalEntry'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :accounted_at, :transfered_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :currency_rate, :emission_amount, :reception_amount, allow_nil: true
  validates_presence_of :currency_rate, :emission_amount, :emission_cash, :emission_currency, :number, :reception_amount, :reception_cash, :reception_currency, :transfered_at
  # ]VALIDATORS]
  validates_length_of :emission_currency, :reception_currency, allow_nil: true, maximum: 3
  validates_numericality_of :emission_amount, greater_than: 0.0
  validates_presence_of :transfered_at

  before_validation do
    self.transfered_at ||= Date.today
    self.emission_currency = emission_cash.currency if emission_cash
    self.reception_currency = reception_cash.currency if reception_cash
    if currency_rate.blank?
      if emission_currency == reception_currency
        self.currency_rate = 1
      else
        self.currency_rate = I18n.currency_rate(emission_currency, reception_currency)
      end
    end
    if emission_amount && currency_rate
      self.reception_amount = currency_rate * emission_amount
    end
  end

  validate do
    errors.add(:reception_cash_id, :invalid) if reception_cash_id == emission_cash_id
  end

  bookkeep do |b|
    transfer_account = Account.find_in_chart(:internal_transfers)
    label = tc(:bookkeep, resource: self.class.model_name.human, number: number, description: description, emission: emission_cash.name, reception: reception_cash.name)
    b.journal_entry(emission_cash.journal, printed_on: self.transfered_at.to_date, column: :emission_journal_entry_id) do |entry|
      entry.add_debit(label, transfer_account.id, emission_amount)
      entry.add_credit(label, emission_cash.account_id, emission_amount)
    end
    b.journal_entry(reception_cash.journal, printed_on: self.transfered_at.to_date, column: :reception_journal_entry_id) do |entry|
      entry.add_debit(label, reception_cash.account_id, reception_amount)
      entry.add_credit(label, transfer_account.id, reception_amount)
    end
  end
end
