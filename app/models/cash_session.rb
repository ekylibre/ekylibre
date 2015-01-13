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
# == Table: cash_sessions
#
#  cash_id              :integer          not null
#  created_at           :datetime         not null
#  creator_id           :integer
#  currency             :string(3)
#  expected_stop_amount :decimal(19, 4)   default(0.0)
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  noticed_start_amount :decimal(19, 4)   default(0.0)
#  noticed_stop_amount  :decimal(19, 4)   default(0.0)
#  sequence_id          :integer
#  started_at           :datetime         not null
#  stopped_at           :datetime
#  updated_at           :datetime         not null
#  updater_id           :integer
#
class CashSession < Ekylibre::Record::Base
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :expected_stop_amount, :noticed_start_amount, :noticed_stop_amount, allow_nil: true
  validates_length_of :currency, allow_nil: true, maximum: 3
  validates_presence_of :cash, :started_at
  #]VALIDATORS]
  has_many :affairs
  belongs_to :cash
  enumerize :currency, in: Nomen::Currencies.all, default: Preference[:currency]
  validate on: :create do
    started_at ||= Time.now
  end
  def zticket
    {
      cash_id: self.id,
      open_cash: self.noticed_start_amount,
      close_cash: self.noticed_stop_amount,
      ticket_count: self.affairs.map(&:deals_count).inject(:+),
      customers_count: 1,
      payment_count: self.affairs.count,
      consolidated_sales: self.affairs.map(&:credit).inject(:+),
      payments: self.affairs.inject([]) do |array, affair|
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
