# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: outgoing_payments
#
#  accounted_at      :datetime
#  affair_id         :integer
#  amount            :decimal(19, 4)   default(0.0), not null
#  bank_check_number :string(255)
#  cash_id           :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer
#  currency          :string(3)        not null
#  delivered         :boolean          default(TRUE), not null
#  downpayment       :boolean          default(TRUE), not null
#  id                :integer          not null, primary key
#  journal_entry_id  :integer
#  lock_version      :integer          default(0), not null
#  mode_id           :integer          not null
#  number            :string(255)
#  paid_at           :datetime
#  payee_id          :integer          not null
#  responsible_id    :integer          not null
#  to_bank_at        :datetime         not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#


class OutgoingPayment < Ekylibre::Record::Base
  belongs_to :cash
  belongs_to :journal_entry
  belongs_to :mode, class_name: "OutgoingPaymentMode"
  belongs_to :payee, class_name: "Entity"
  belongs_to :responsible, class_name: "User"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :accounted_at, :paid_at, :to_bank_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_length_of :bank_check_number, :number, allow_nil: true, maximum: 255
  validates_inclusion_of :delivered, :downpayment, in: [true, false]
  validates_presence_of :amount, :cash, :currency, :mode, :payee, :responsible, :to_bank_at
  #]VALIDATORS]
  validates_numericality_of :amount, greater_than: 0
  validates_presence_of :to_bank_at

  acts_as_numbered
  acts_as_affairable :payee, dealt_at: :to_bank_at, debit: false, role: "supplier"

  before_validation do
    if self.mode
      self.cash = self.mode.cash
      self.currency = self.mode.currency
    end
  end

  protect do
    (self.journal_entry && self.journal_entry.closed?)
  end

  # This method permits to add journal entries corresponding to the payment
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    # attorney_amount = self.attorney_amount
    supplier_amount = self.amount #  - attorney_amount
    label = tc(:bookkeep, :resource => self.class.model_name.human, :number => self.number, :payee => self.payee.full_name, :mode => self.mode.name, :check_number => self.bank_check_number) # , :expenses => self.uses.collect{|p| p.expense.number}.to_sentence
    b.journal_entry(self.mode.cash.journal, printed_on: self.to_bank_at.to_date, :unless => (!self.mode.with_accounting? or !self.delivered)) do |entry|
      entry.add_debit(label, self.payee.account(:supplier).id, supplier_amount) unless supplier_amount.zero?
      # entry.add_debit(label, self.payee.account(:attorney).id, attorney_amount) unless attorney_amount.zero?
      entry.add_credit(label, self.mode.cash.account_id, self.amount)
    end
  end

  def label
    tc(:label, :amount => self.amount.l(currency: self.currency), :date => self.to_bank_at.l, :mode => self.mode.name, :payee => self.payee.full_name, :number => self.number)
  end

end
