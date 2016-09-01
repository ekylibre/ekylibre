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
# == Table: cash_transfers
#
#  accounted_at               :datetime
#  created_at                 :datetime         not null
#  creator_id                 :integer
#  currency_rate              :decimal(19, 10)  not null
#  custom_fields              :jsonb
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
  include Customizable
  acts_as_numbered
  attr_readonly :number
  refers_to :emission_currency, class_name: 'Currency'
  belongs_to :emission_cash, class_name: 'Cash'
  belongs_to :emission_journal_entry, class_name: 'JournalEntry'
  refers_to :reception_currency, class_name: 'Currency'
  belongs_to :reception_cash, class_name: 'Cash'
  belongs_to :reception_journal_entry, class_name: 'JournalEntry'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :currency_rate, presence: true, numericality: { greater_than: -1_000_000_000, less_than: 1_000_000_000 }
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :emission_amount, :reception_amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :emission_cash, :emission_currency, :reception_cash, :reception_currency, presence: true
  validates :number, presence: true, length: { maximum: 500 }
  validates :transfered_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  # ]VALIDATORS]
  validates :emission_currency, :reception_currency, length: { allow_nil: true, maximum: 3 }
  validates :emission_amount, numericality: { greater_than: 0.0 }
  validates :transfered_at, presence: true

  before_validation do
    self.transfered_at ||= Time.zone.today
    self.emission_currency = emission_cash.currency if emission_cash
    self.reception_currency = reception_cash.currency if reception_cash
    if currency_rate.blank?
      self.currency_rate = if emission_currency == reception_currency
                             1
                           else
                             I18n.currency_rate(emission_currency, reception_currency)
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
    transfer_account = Account.find_in_nomenclature(:internal_transfers)
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
