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

  [[:items_count, :items, [:unity, :hectare, :unity_per_hectare]], [:net_mass, :mass, [:kilogram, :square_meter, :kilogram_per_square_meter]]].each do |long_name, short_name, unit|
    define_method "marketable_#{long_name}" do
      if inspection.send("unmarketable_#{short_name}_rate")
        send("total_#{long_name}") * (1 - inspection.send("unmarketable_#{short_name}_rate"))
      end
    end

    define_method "marketable_#{short_name}_yield" do
      unit_name = if respond_to?("grading_#{long_name}_unit")
                    send("grading_#{long_name}_unit").name + '_per_' + product_net_surface_area.unit.to_s
                  else
                    ''
                  end
      unit_name = unit.last unless Nomen::Unit.find(unit_name)
      y = (send("marketable_#{long_name}").to_d(unit.first) / product_net_surface_area.to_d(unit.second)).in(unit.last)
      y.in(unit_name).round(0)
    end
  end
end
