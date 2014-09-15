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
# == Table: cash_transfers
#
#  accounted_at               :datetime
#  created_at                 :datetime         not null
#  creator_id                 :integer
#  currency_rate              :decimal(19, 10)  not null
#  description                :text
#  emission_amount            :decimal(19, 4)   not null
#  emission_cash_id           :integer          not null
#  emission_currency          :string(3)        not null
#  emission_journal_entry_id  :integer
#  id                         :integer          not null, primary key
#  lock_version               :integer          default(0), not null
#  number                     :string(255)      not null
#  reception_amount           :decimal(19, 4)   not null
#  reception_cash_id          :integer          not null
#  reception_currency         :string(3)        not null
#  reception_journal_entry_id :integer
#  transfered_at              :datetime         not null
#  updated_at                 :datetime         not null
#  updater_id                 :integer
#


class CashTransfer < Ekylibre::Record::Base
  acts_as_numbered
  attr_readonly :number
  belongs_to :emission_cash, class_name: "Cash"
  belongs_to :emission_journal_entry, class_name: "JournalEntry"
  belongs_to :reception_cash, class_name: "Cash"
  belongs_to :reception_journal_entry, class_name: "JournalEntry"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :currency_rate, :emission_amount, :reception_amount, allow_nil: true
  validates_length_of :emission_currency, :reception_currency, allow_nil: true, maximum: 3
  validates_length_of :number, allow_nil: true, maximum: 255
  validates_presence_of :currency_rate, :emission_amount, :emission_cash, :emission_currency, :number, :reception_amount, :reception_cash, :reception_currency, :transfered_at
  #]VALIDATORS]
  validates_numericality_of :emission_amount, greater_than: 0.0
  validates_presence_of :transfered_at

  before_validation do
    self.transfered_at ||= Date.today
    if self.currency_rate.blank?
      if self.emission_currency == self.reception_currency
        self.currency_rate = 1
      else
        self.currency_rate = I18n.currency_rate(self.emission_currency, self.reception_currency)
      end
    end
    if self.emission_amount and self.currency_rate
      self.reception_amount = self.currency_rate * self.emission_amount
    end
  end

  validate do
    errors.add(:reception_cash_id, :invalid) if self.reception_cash_id == self.emission_cash_id
  end

  bookkeep do |b|
    transfer_account = Account.find_in_chart(:internal_transfers)
    label = tc(:bookkeep, resource: self.class.model_name.human, number: self.number, description: self.description, emission: self.emission_cash.name, reception: self.reception_cash.name)
    b.journal_entry(self.emission_cash.journal, printed_at: self.transfered_at, column: :emission_journal_entry_id) do |entry|
      entry.add_debit( label, transfer_account.id, self.emission_amount)
      entry.add_credit(label, self.emission_cash.account_id, self.emission_amount)
    end
    b.journal_entry(self.reception_cash.journal, printed_at: self.transfered_at, column: :reception_journal_entry_id) do |entry|
      entry.add_debit( label, self.reception_cash.account_id, self.reception_amount)
      entry.add_credit(label, transfer_account.id, self.reception_amount)
    end
  end

end
