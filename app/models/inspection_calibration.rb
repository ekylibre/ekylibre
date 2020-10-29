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
# == Table: inspection_calibrations
#
#  created_at         :datetime         not null
#  creator_id         :integer
#  id                 :integer          not null, primary key
#  inspection_id      :integer          not null
#  items_count_value  :integer
#  lock_version       :integer          default(0), not null
#  maximal_size_value :decimal(19, 4)
#  minimal_size_value :decimal(19, 4)
#  nature_id          :integer          not null
#  net_mass_value     :decimal(19, 4)
#  updated_at         :datetime         not null
#  updater_id         :integer
#
class InspectionCalibration < Ekylibre::Record::Base
  include Inspectable
  belongs_to :nature, class_name: 'ActivityInspectionCalibrationNature', inverse_of: :inspection_calibrations
  belongs_to :inspection, inverse_of: :calibrations
  has_one :product, through: :inspection
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :items_count_value, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :maximal_size_value, :minimal_size_value, :net_mass_value, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :inspection, :nature, presence: true
  # ]VALIDATORS]

  delegate :name, to: :nature

  scope :of_scale, ->(scale) { joins(:nature).where(activity_inspection_calibration_natures: { scale_id: scale }).order('minimal_size_value', 'maximal_size_value') }
  scope :marketable, -> { where(nature: ActivityInspectionCalibrationNature.marketable) }
  scope :of_products, ->(*products) { joins(:inspection).where(inspections: { product_id: products.map(&:id) }) }

  def marketable?
    nature.marketable
  end

  def marketable_quantity(dimension)
    return 0.in(quantity_unit(dimension)) unless inspection.unmarketable_rate(dimension)

    coeff = 1 - inspection.unmarketable_rate(dimension)
    projected_total(dimension) * coeff
  end

  def marketable_yield(dimension)
    market_quantity = marketable_quantity(dimension).to_d(quantity_unit(dimension))
    y = (market_quantity / total_area).in(default_per_area_unit(dimension))
    y.in(quantity_per_area_unit(dimension))
  end
end
