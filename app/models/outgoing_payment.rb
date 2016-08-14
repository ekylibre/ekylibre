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
# == Table: outgoing_payments
#
#  accounted_at      :datetime
#  affair_id         :integer
#  amount            :decimal(19, 4)   default(0.0), not null
#  bank_check_number :string
#  cash_id           :integer          not null
#  created_at        :datetime         not null
#  creator_id        :integer
#  currency          :string           not null
#  custom_fields     :jsonb
#  delivered         :boolean          default(TRUE), not null
#  downpayment       :boolean          default(TRUE), not null
#  id                :integer          not null, primary key
#  journal_entry_id  :integer
#  lock_version      :integer          default(0), not null
#  mode_id           :integer          not null
#  number            :string
#  paid_at           :datetime
#  payee_id          :integer          not null
#  responsible_id    :integer          not null
#  to_bank_at        :datetime         not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#

class OutgoingPayment < Ekylibre::Record::Base
  include Attachable
  include Customizable
  include PeriodicCalculable
  refers_to :currency
  belongs_to :cash
  belongs_to :journal_entry
  belongs_to :mode, class_name: 'OutgoingPaymentMode'
  belongs_to :payee, class_name: 'Entity'
  belongs_to :responsible, class_name: 'User'
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, :paid_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :bank_check_number, :number, length: { maximum: 500 }, allow_blank: true
  validates :cash, :currency, :mode, :payee, :responsible, presence: true
  validates :delivered, :downpayment, inclusion: { in: [true, false] }
  validates :to_bank_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :amount, numericality: { greater_than: 0 }
  validates :to_bank_at, presence: true

  acts_as_numbered
  acts_as_affairable :payee, dealt_at: :to_bank_at, debit: false, role: 'supplier'

  scope :between, lambda { |started_at, stopped_at|
    where(paid_at: started_at..stopped_at)
  }

  alias status affair_status

  calculable period: :month, column: :amount, at: :paid_at, name: :sum

  before_validation do
    if mode
      self.cash = mode.cash
      self.currency = mode.currency
    end
  end

  protect do
    (journal_entry && journal_entry.closed?)
  end

  # This method permits to add journal entries corresponding to the payment
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    label = tc(:bookkeep, resource: self.class.model_name.human, number: number, payee: payee.full_name, mode: mode.name, check_number: bank_check_number)
    b.journal_entry(mode.cash.journal, printed_on: to_bank_at.to_date, if: (mode.with_accounting? && delivered)) do |entry|
      entry.add_debit(label, payee.account(:supplier).id, amount)
      entry.add_credit(label, mode.cash.account_id, amount)
    end
  end

  def label
    tc(:label, amount: amount.l(currency: currency), date: to_bank_at.l, mode: mode.name, payee: payee.full_name, number: number)
  end
end
