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
# == Table: activity_budgets
#
#  activity_id        :integer          not null
#  amount             :decimal(19, 4)   default(0.0)
#  campaign_id        :integer          not null
#  computation_method :string           not null
#  created_at         :datetime         not null
#  creator_id         :integer
#  currency           :string           not null
#  direction          :string           not null
#  id                 :integer          not null, primary key
#  lock_version       :integer          default(0), not null
#  quantity           :decimal(19, 4)   default(0.0)
#  unit_amount        :decimal(19, 4)   default(0.0)
#  unit_currency      :string           not null
#  unit_population    :decimal(19, 4)
#  updated_at         :datetime         not null
#  updater_id         :integer
#  variant_id         :integer
#  variant_indicator  :string
#  variant_unit       :string
#

class ActivityBudget < Ekylibre::Record::Base
  refers_to :currency
  enumerize :direction, in: [:revenue, :expense], predicates: true
  enumerize :computation_method, in: [:per_production, :per_production_support, :per_working_unit], default: :per_working_unit, predicates: true
  # refers_to :variant_indicator, class_name: 'Indicator' # in: Activity.support_variant_indicator.values
  # refers_to :variant_unit, class_name: 'Unit'

  belongs_to :activity, inverse_of: :budgets
  belongs_to :variant, class_name: 'ProductNatureVariant'
  has_many :productions, through: :activity

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :quantity, :unit_amount, :unit_population, allow_nil: true
  validates_presence_of :activity, :computation_method, :currency, :direction, :unit_currency
  # ]VALIDATORS]
  validates_presence_of :variant, :activity

  delegate :supports_quantity, :supports_count, :support_indicator, :support_unit, to: :activity
  delegate :name, to: :variant, prefix: true

  scope :revenues, -> { where(direction: :revenue) }
  scope :expenses, -> { where(direction: :expense) }

  before_validation do
    self.unit_currency = Preference[:currency] if unit_currency.blank?
    self.currency = unit_currency if currency.blank?
  end

  validate do
    if currency && unit_currency
      errors.add(:currency, :invalid) if currency != unit_currency
    end
  end

  after_validation do
    self.amount = unit_amount * quantity * coefficient
  end

  # Computes the coefficient to use for amount computation
  def coefficient(_options = {})
    return 0 unless activity
    if self.per_production_support?
      return supports_count
    elsif self.per_working_unit?
      return supports_quantity
    end
    1
  end
end
