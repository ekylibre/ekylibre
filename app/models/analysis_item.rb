# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
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
# == Table: analysis_items
#
#  absolute_measure_value_unit  :string(255)
#  absolute_measure_value_value :decimal(19, 4)
#  analysis_id                  :integer          not null
#  annotation                   :text
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
#  point_value                  :spatial({:srid=>
#  product_reading_id           :integer
#  string_value                 :text
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#
class AnalysisItem < Ekylibre::Record::Base
  include ReadingStorable
  belongs_to :analysis
  belongs_to :product_reading, dependent: :destroy
  has_one :product, through: :analysis
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :integer_value, allow_nil: true, only_integer: true
  validates_numericality_of :absolute_measure_value_value, :decimal_value, :measure_value_value, allow_nil: true
  validates_length_of :absolute_measure_value_unit, :choice_value, :indicator_datatype, :indicator_name, :measure_value_unit, allow_nil: true, maximum: 255
  validates_inclusion_of :boolean_value, in: [true, false]
  validates_presence_of :analysis, :indicator_datatype, :indicator_name
  #]VALIDATORS]

  delegate :sampled_at, to: :analysis

  after_save do
    if self.product
      if reading = self.product_reading
        reading.read_at = self.sampled_at
        reading.value = self.value
        reading.save!
      else
        reading = self.product.read!(indicator, self.value, at: self.sampled_at)
        self.update_column(:product_reading_id, reading.id)
      end
    end
  end

end
