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
# == Table: cash_sessions
#
#  cash_id              :integer          not null
#  created_at           :datetime         not null
#  creator_id           :integer
#  currency             :string
#  expected_stop_amount :decimal(19, 4)   default(0.0)
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  noticed_start_amount :decimal(19, 4)   default(0.0)
#  noticed_stop_amount  :decimal(19, 4)   default(0.0)
#  number               :string
#  started_at           :datetime         not null
#  stopped_at           :datetime
#  updated_at           :datetime         not null
#  updater_id           :integer
#
class CashSession < Ekylibre::Record::Base
  belongs_to :cash
  has_many :affairs
  refers_to :currency
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :expected_stop_amount, :noticed_start_amount, :noticed_stop_amount, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :number, length: { maximum: 500 }, allow_blank: true
  validates :started_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :stopped_at, timeliness: { on_or_after: ->(cash_session) { cash_session.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :cash, presence: true
  # ]VALIDATORS]
  validates :currency, length: { allow_nil: true, maximum: 3 }
  validates :number, uniqueness: { scope: :cash_id, allow_nil: true }
  validates :number, presence: true
  validates :number, format: { with: /\A\d+\z/ }

  scope :actives, -> { where(stopped_at: nil) }

  before_validation do
    self.started_at ||= Time.zone.now
    self.currency = cash.currency if cash
  end

  before_validation(on: :create) do
    if cash && number.blank?
      self.number ||= (cash.sessions.maximum('CAST(number AS INTEGER)') || 0) + 1
    end
  end

  def zticket
    {
      cash_id: id,
      open_cash: noticed_start_amount,
      close_cash: noticed_stop_amount,
      ticket_count: affairs.map(&:deals_count).inject(:+),
      customers_count: 1,
      payment_count: affairs.count,
      consolidated_sales: affairs.map(&:credit).inject(:+),
      payments: affairs.inject([]) do |array, affair|
        array << affair.incoming_payments.map do |payment|
          {
            id: payment.id,
            _type: payment.mode.name,
            amount: payment.amount,
            currency: payment.currency,
            currency_amount: nil
          }.to_struct
        end
      end.flatten,
      taxes: [],
      category_sales: []
    }.to_struct
  end
end
