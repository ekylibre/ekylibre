# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: intervention_parameter_readings
#
#  absolute_measure_value_unit  :string
#  absolute_measure_value_value :decimal(19, 4)
#  boolean_value                :boolean          default(FALSE), not null
#  choice_value                 :string
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  decimal_value                :decimal(19, 4)
#  geometry_value               :geometry({:srid=>4326, :type=>"geometry"})
#  id                           :integer          not null, primary key
#  indicator_datatype           :string           not null
#  indicator_name               :string           not null
#  integer_value                :integer
#  lock_version                 :integer          default(0), not null
#  measure_value_unit           :string
#  measure_value_value          :decimal(19, 4)
#  multi_polygon_value          :geometry({:srid=>4326, :type=>"multi_polygon"})
#  parameter_id                 :integer          not null
#  point_value                  :geometry({:srid=>4326, :type=>"point"})
#  string_value                 :text
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#

class InterventionParameterReading < Ekylibre::Record::Base
  include ReadingStorable
  belongs_to :intervention_parameter, class_name: 'InterventionProductParameter', foreign_key: :parameter_id, inverse_of: :readings
  has_one :intervention, through: :intervention_parameter
  has_one :product, through: :intervention_parameter
  has_one :product_reading, as: :originator
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :absolute_measure_value_unit, :choice_value, length: { maximum: 500 }, allow_blank: true
  validates :absolute_measure_value_value, :decimal_value, :measure_value_value, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :boolean_value, inclusion: { in: [true, false] }
  validates :indicator_datatype, :indicator_name, :intervention_parameter, presence: true
  validates :integer_value, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :string_value, length: { maximum: 500_000 }, allow_blank: true
  # ]VALIDATORS]
  validates :indicator_name, uniqueness: { scope: :parameter_id }

  delegate :started_at, :stopped_at, to: :intervention

  validate do
    if product && indicator
      unless product.indicators.include?(indicator)
        errors.add(:indicator_name, :invalid)
      end
    end
  end

  after_commit do
    if product
      product_reading ||= product.readings.new(indicator: indicator)
      product_reading.originator = self
      product_reading.value = value
      product_reading.read_at = product.born_at || intervention.started_at || Time.now
      product_reading.save!
    end
  end
end
