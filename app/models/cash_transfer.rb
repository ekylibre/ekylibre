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
# == Table: cash_transfers
#
#  accounted_at              :datetime         
#  comment                   :text             
#  created_at                :datetime         not null
#  created_on                :date             
#  creator_id                :integer          
#  currency_rate             :decimal(19, 10)  default(1.0), not null
#  emitter_amount            :decimal(19, 4)   default(0.0), not null
#  emitter_cash_id           :integer          not null
#  emitter_journal_entry_id  :integer          
#  id                        :integer          not null, primary key
#  lock_version              :integer          default(0), not null
#  number                    :string(255)      not null
#  receiver_amount           :decimal(19, 4)   default(0.0), not null
#  receiver_cash_id          :integer          not null
#  receiver_journal_entry_id :integer          
#  updated_at                :datetime         not null
#  updater_id                :integer          
#


class CashTransfer < CompanyRecord
  acts_as_numbered
  attr_readonly :number
  belongs_to :emitter_cash, :class_name => "Cash"
  belongs_to :emitter_journal_entry, :class_name => "JournalEntry"
  belongs_to :receiver_cash, :class_name => "Cash"
  belongs_to :receiver_journal_entry, :class_name => "JournalEntry"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :currency_rate, :emitter_amount, :receiver_amount, :allow_nil => true
  validates_length_of :number, :allow_nil => true, :maximum => 255
  validates_presence_of :currency_rate, :emitter_amount, :emitter_cash, :number, :receiver_amount, :receiver_cash
  #]VALIDATORS]
  validates_numericality_of :emitter_amount, :receiver_amount, :greater_than => 0.0
  validates_presence_of :created_on

  before_validation do
    self.created_on ||= Date.today
    # TODO Write test for CashTransfer
  end

  validate do
    errors.add(:receiver_cash_id, :invalid) if self.receiver_cash_id == self.emitter_cash_id
  end

  bookkeep do |b|
    preference = Preference[:financial_internal_transfers_accounts]
    transfer_account = Account.get(preference.value, preference.label)
    label = tc(:bookkeep, :resource => self.class.model_name.human, :number => self.number, :comment => self.comment, :emitter => self.emitter_cash.name, :receiver => self.receiver_cash.name)
    b.journal_entry(self.emitter_cash.journal, :column => :emitter_journal_entry_id) do |entry|
      entry.add_debit( label, transfer_account.id, self.emitter_amount)
      entry.add_credit(label, self.emitter_cash.account_id, self.emitter_amount)
    end
    b.journal_entry(self.receiver_cash.journal, :column => :receiver_journal_entry_id) do |entry|
      entry.add_debit( label, self.receiver_cash.account_id, self.receiver_amount)
      entry.add_credit(label, transfer_account.id, self.receiver_amount)
    end
  end

end
