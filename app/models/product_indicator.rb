# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: product_indicators
#
#  boolean_value   :boolean          not null
#  choice_value_id :integer
#  created_at      :datetime         not null
#  creator_id      :integer
#  decimal_value   :decimal(19, 4)
#  description     :string(255)
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  measure_unit_id :integer
#  measure_value   :decimal(19, 4)
#  measured_at     :datetime         not null
#  nature_id       :integer          not null
#  product_id      :integer          not null
#  string_value    :text
#  updated_at      :datetime         not null
#  updater_id      :integer
#


class ProductIndicator < Ekylibre::Record::Base
  attr_accessible :product_id, :nature_id, :measured_at, :description, :decimal_value, :measure_value, :string_value, :boolean_value, :choice_value_id
  belongs_to :product, :class_name => "Product"
  belongs_to :nature, :class_name => "ProductIndicatorNature", :inverse_of => :indicators
  belongs_to :measure_unit, :class_name => "Unit"
  belongs_to :choice_value, :class_name => "ProductIndicatorNatureChoice", :inverse_of => :data
  #[VALIDATORS[ Do not edit these items directly. Use `rake clean:validations`.
  validates_numericality_of :decimal_value, :measure_value, :allow_nil => true
  validates_length_of :description, :allow_nil => true, :maximum => 255
  validates_inclusion_of :boolean_value, :in => [true, false]
  validates_presence_of :measured_at, :nature, :product
  #]VALIDATORS]
end
