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
# == Table: product_nature_variant_indicator_data
#
#  boolean_value       :boolean          not null
#  choice_value        :string(255)
#  computation_method  :string(255)      not null
#  created_at          :datetime         not null
#  creator_id          :integer
#  decimal_value       :decimal(19, 4)
#  geometry_value      :spatial({:srid=>
#  id                  :integer          not null, primary key
#  indicator           :string(255)      not null
#  indicator_datatype  :string(255)      not null
#  lock_version        :integer          default(0), not null
#  measure_value_unit  :string(255)
#  measure_value_value :decimal(19, 4)
#  multi_polygon_value :spatial({:srid=>
#  point_value         :spatial({:srid=>
#  string_value        :text
#  updated_at          :datetime         not null
#  updater_id          :integer
#  variant_id          :integer          not null
#


class ProductNatureVariantIndicatorDatum < IndicatorDatum
  # attr_accessible :created_at, :variant_id, :description
  belongs_to :variant, class_name: "ProductNatureVariant"
  enumerize :computation_method, in: [:frozen, :proportional], default: :frozen

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  #]VALIDATORS]

  validate do
    unless self.variant.frozen_indicators_array.map(&:name).include?(self.indicator.to_s)
      errors.add(:indicator, :invalid)
    end
  end

end
