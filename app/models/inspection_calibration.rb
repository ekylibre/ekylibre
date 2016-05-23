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
# == Table: inspection_calibrations
#
#  created_at         :datetime         not null
#  creator_id         :integer
#  id                 :integer          not null, primary key
#  inspection_id      :integer          not null
#  items_count        :integer
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
  validates_numericality_of :maximal_size_value, :minimal_size_value, :net_mass_value, allow_nil: true
  validates_presence_of :inspection, :nature
  # ]VALIDATORS]

  delegate :name, to: :nature
  
  scope :of_scale, ->(scale) { joins(:nature).where(activity_inspection_calibration_natures: { scale_id: scale }).order('minimal_size_value', 'maximal_size_value') }
  scope :marketable, -> { where(nature: ActivityInspectionCalibrationNature.marketable) }
  scope :of_products, ->(*products) { joins(:inspection).where(inspections: { product_id: products.map(&:id) }) }

  def marketable?
    nature.marketable
  end

  def marketable_net_mass
    total_net_mass * (1 - inspection.unmarketable_rate)
  end

  def marketable_yield
    unit_name = "#{grading_net_mass_unit.name}_per_#{product_net_surface_area.unit}"
    unit_name = :kilogram_per_hectare unless Nomen::Unit.find(unit_name)
    y = (marketable_net_mass.to_d(:kilogram) / product_net_surface_area.to_d(:square_meter)).in(:kilogram_per_square_meter)
    y.in(unit_name).round(0)
  end
end
