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
# == Table: cash_transfers
#
#  accounted_at              :datetime         
#  comment                   :text             
#  company_id                :integer          not null
#  created_at                :datetime         not null
#  created_on                :date             
#  creator_id                :integer          
#  currency_id               :integer          
#  emitter_amount            :decimal(16, 2)   default(0.0), not null
#  emitter_cash_id           :integer          not null
#  emitter_currency_id       :integer          not null
#  emitter_currency_rate     :decimal(16, 6)   default(1.0), not null
#  emitter_journal_entry_id  :integer          
#  id                        :integer          not null, primary key
#  lock_version              :integer          default(0), not null
#  number                    :string(255)      not null
#  receiver_amount           :decimal(16, 2)   default(0.0), not null
#  receiver_cash_id          :integer          not null
#  receiver_currency_id      :integer          
#  receiver_currency_rate    :decimal(16, 6)   
#  receiver_journal_entry_id :integer          
#  updated_at                :datetime         not null
#  updater_id                :integer          
#


class CashTransfer < CompanyRecord
  acts_as_numbered
  attr_readonly :company_id, :number
  belongs_to :company
  belongs_to :currency
  belongs_to :emitter_cash, :class_name=>"Cash"
  belongs_to :emitter_currency, :class_name=>"Currency"
  belongs_to :emitter_journal_entry, :class_name=>"JournalEntry"
  belongs_to :receiver_cash, :class_name=>"Cash"
  belongs_to :receiver_currency, :class_name=>"Currency"
  belongs_to :receiver_journal_entry, :class_name=>"JournalEntry"
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :emitter_amount, :emitter_currency_rate, :receiver_amount, :receiver_currency_rate, :allow_nil => true
  validates_length_of :number, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  validates_numericality_of :emitter_amount, :receiver_amount, :greater_than=>0.0
  validates_presence_of :receiver_amount, :emitter_amount, :created_on

  before_validation do
    self.created_on ||= Date.today
    self.currency ||= self.company.default_currency

    if self.currency == self.company.default_currency
      if self.emitter_cash
        self.emitter_currency ||= self.emitter_cash.currency
        self.emitter_currency_rate ||= self.emitter_currency.rate
      end
      if self.receiver_cash
        self.receiver_currency ||= self.receiver_cash.currency
        self.receiver_currency_rate ||= self.receiver_currency.rate
      end
    end

    if self.emitter_amount.to_f > 0
      self.receiver_amount = self.emitter_amount*self.emitter_currency_rate/self.receiver_currency_rate
    elsif self.receiver_amount.to_f > 0
      self.emitter_amount = self.receiver_amount*self.receiver_currency_rate/self.emitter_currency_rate
    end

    if self.number.blank?
      last = self.company.cash_transfers.find(:first, :order=>"number desc")
      self.number = last ? last.number.succ! : '00000001'
    end

  end

  validate do
    errors.add(:receiver_cash_id, :invalid) if self.receiver_cash_id == self.emitter_cash_id
  end

  bookkeep do |b|
    preference = self.company.preference("financial_internal_transfers_accounts")
    transfer_account = self.company.account(preference.value, preference.label)
    label = tc(:bookkeep, :resource=>self.class.model_name.human, :number=>self.number, :comment=>self.comment, :emitter=>self.emitter_cash.name, :receiver=>self.receiver_cash.name)
    b.journal_entry(self.emitter_cash.journal, :column=>:emitter_journal_entry_id) do |entry|
      entry.add_debit( label, transfer_account.id, self.emitter_amount)      
      entry.add_credit(label, self.emitter_cash.account_id, self.emitter_amount)
    end
    b.journal_entry(self.receiver_cash.journal, :column=>:receiver_journal_entry_id) do |entry|
      entry.add_debit( label, self.receiver_cash.account_id, self.receiver_amount)
      entry.add_credit(label, transfer_account.id, self.receiver_amount)
    end
  end

end
