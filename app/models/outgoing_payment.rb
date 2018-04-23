# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
#  delivered         :boolean          default(FALSE), not null
#  downpayment       :boolean          default(FALSE), not null
#  id                :integer          not null, primary key
#  journal_entry_id  :integer
#  list_id           :integer
#  lock_version      :integer          default(0), not null
#  mode_id           :integer          not null
#  number            :string
#  paid_at           :datetime
#  payee_id          :integer          not null
#  position          :integer
#  responsible_id    :integer          not null
#  to_bank_at        :datetime         not null
#  type              :string
#  updated_at        :datetime         not null
#  updater_id        :integer
#

class OutgoingPayment < Ekylibre::Record::Base
  include Attachable
  include Customizable
  include PeriodicCalculable
  include Letterable
  refers_to :currency
  belongs_to :cash
  belongs_to :journal_entry
  belongs_to :mode, class_name: 'OutgoingPaymentMode'
  belongs_to :payee, class_name: 'Entity'
  belongs_to :responsible, class_name: 'User'
  belongs_to :list, class_name: 'OutgoingPaymentList', inverse_of: :payments
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :accounted_at, :paid_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :amount, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :bank_check_number, :number, length: { maximum: 500 }, allow_blank: true
  validates :cash, :currency, :mode, :payee, :responsible, presence: true
  validates :delivered, :downpayment, inclusion: { in: [true, false] }
  validates :to_bank_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :amount, numericality: true
  validates :to_bank_at, presence: true

  delegate :full_name, to: :payee, prefix: true

  acts_as_numbered
  acts_as_affairable :payee, dealt_at: :to_bank_at, debit: false

  scope :between, lambda { |started_at, stopped_at|
    where(paid_at: started_at..stopped_at)
  }

  alias status affair_status

  scope :matching_cash, ->(id) { includes(:mode).where(outgoing_payment_modes: { cash_id: id }) }

  calculable period: :month, column: :amount, at: :paid_at, name: :sum

  after_initialize if: :new_record? do
    self.delivered = true
    self.downpayment = true
  end

  before_validation do
    self.paid_at ||= Time.zone.now if delivered
    if mode
      self.cash = mode.cash
      self.currency = mode.currency
    end
  end

  protect do
    (journal_entry && journal_entry.closed?) ||
      pointed_by_bank_statement? || list.present?
  end

  delegate :third_attribute, to: :class

  def pointed_by_bank_statement?
    journal_entry && journal_entry.items.where('LENGTH(TRIM(bank_statement_letter)) > 0').any?
  end

  def self.third_attribute
    :payee
  end

  def self.sign_of_amount
    -1
  end

  def relative_amount
    self.class.sign_of_amount * amount
  end

  def third
    send(third_attribute)
  end

  def amount_to_letter
    c = Nomen::Currency[currency]
    precision = c.precision
    integers, decimals = amount.round(precision).divmod(1)
    decimals = (decimals * 10**precision).round
    locale = I18n.t('i18n.iso2').to_sym
    items = [integers.to_i.humanize(locale: locale) + ' ' + c.human_name.downcase.pluralize]
    if decimals > 0
      if precision == 0
      # OK
      elsif precision == 2
        items << :x_cents.tl(count: decimals).gsub(decimals.to_s, decimals.humanize(locale: locale))
      elsif precision == 3
        items << :x_mills.tl(count: decimals).gsub(decimals.to_s, decimals.humanize(locale: locale))
      else
        raise 'Invalid precision: ' + precision.inspect
      end
    end
    items.to_sentence
  end

  def affair_reference_numbers
    affair.purchase_invoices.map(&:reference_number).compact.to_sentence
  end

  def label
    tc(:label, amount: amount.l(currency: currency), date: to_bank_at.l, mode: mode.name, payee: payee.full_name, number: number)
  end
end
