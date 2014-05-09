# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: product_reading_tasks
#
#  absolute_measure_value_unit  :string(255)
#  absolute_measure_value_value :decimal(19, 4)
#  boolean_value                :boolean          not null
#  choice_value                 :string(255)
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  decimal_value                :decimal(19, 4)
#  geometry_value               :spatial({:srid=>
#  id                           :integer          not null, primary key
#  indicator_datatype           :string(255)      not null
#  indicator_name               :string(255)      not null
#  integer_value                :integer
#  lock_version                 :integer          default(0), not null
#  measure_value_unit           :string(255)
#  measure_value_value          :decimal(19, 4)
#  operation_id                 :integer
#  originator_id                :integer
#  originator_type              :string(255)
#  point_value                  :spatial({:srid=>
#  product_id                   :integer          not null
#  reporter_id                  :integer
#  started_at                   :datetime         not null
#  stopped_at                   :datetime
#  string_value                 :text
#  tool_id                      :integer
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#
class ProductReadingTask < Ekylibre::Record::Base
  include Taskable, TimeLineable, ReadingStorable
  belongs_to :product
  belongs_to :reporter, class_name: "Worker"
  belongs_to :tool, class_name: "Product"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :integer_value, allow_nil: true, only_integer: true
  validates_numericality_of :absolute_measure_value_value, :decimal_value, :measure_value_value, allow_nil: true
  validates_length_of :absolute_measure_value_unit, :choice_value, :indicator_datatype, :indicator_name, :measure_value_unit, :originator_type, allow_nil: true, maximum: 255
  validates_inclusion_of :boolean_value, in: [true, false]
  validates_presence_of :indicator_datatype, :indicator_name, :product, :started_at
  #]VALIDATORS]

  validate do
    if self.product and self.indicator
      unless self.product.indicators.include?(self.indicator)
        errors.add(:indicator_name, :invalid)
      end
    end
  end

  after_create do
    self.product.read!(self.indicator, self.value, at: self.started_at)
    # reading = self.product_readings.build(product: self.product, indicator: self.indicator, read_at: self.stopped_at)
    # reading.value = self.value
    # reading.save!
  end

  def siblings
    self.product.reading_tasks
  end

end
