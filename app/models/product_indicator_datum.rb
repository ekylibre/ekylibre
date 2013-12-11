# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2013 Brice Texier, David Joulin
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
# == Table: product_indicator_data
#
#  boolean_value       :boolean          not null
#  choice_value        :string(255)
#  created_at          :datetime         not null
#  creator_id          :integer
#  decimal_value       :decimal(19, 4)
#  geometry_value      :spatial({:srid=>
#  id                  :integer          not null, primary key
#  indicator_datatype  :string(255)      not null
#  indicator_name      :string(255)      not null
#  lock_version        :integer          default(0), not null
#  measure_value_unit  :string(255)
#  measure_value_value :decimal(19, 4)
#  measured_at         :datetime         not null
#  multi_polygon_value :spatial({:srid=>
#  originator_id       :integer
#  originator_type     :string(255)
#  point_value         :spatial({:srid=>
#  product_id          :integer          not null
#  string_value        :text
#  updated_at          :datetime         not null
#  updater_id          :integer
#


class ProductIndicatorDatum < Ekylibre::Record::Base
  include IndicatorDatumStorable, PeriodicCalculable
  belongs_to :product, inverse_of: :indicator_data
  belongs_to :originator, polymorphic: true
  has_one :variant, through: :product
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :decimal_value, :measure_value_value, allow_nil: true
  validates_length_of :choice_value, :indicator_datatype, :indicator_name, :measure_value_unit, :originator_type, allow_nil: true, maximum: 255
  validates_inclusion_of :boolean_value, in: [true, false]
  validates_presence_of :indicator_datatype, :indicator_name, :measured_at, :product
  #]VALIDATORS]

  scope :between, lambda { |started_on, stopped_on|
    where("measured_at BETWEEN ? AND ?", started_on, stopped_on)
  }
  scope :measured_between, lambda { |started_on, stopped_on| between(started_on, stopped_on) }
  scope :of_products, lambda { |products, indicator_name, at = nil|
    at ||= Time.now
    where("id IN (SELECT p1.id FROM #{self.indicator_table_name(indicator_name)} AS p1 LEFT OUTER JOIN #{self.indicator_table_name(indicator_name)} AS p2 ON (p1.product_id = p2.product_id AND p1.indicator_name = p2.indicator_name AND (p1.measured_at < p2.measured_at OR (p1.measured_at = p2.measured_at AND p1.id < p2.id)) AND p2.measured_at <= ?) WHERE p1.measured_at <= ? AND p1.product_id IN (?) AND p1.indicator_name = ? AND p2 IS NULL)", at, at, products.pluck(:id), indicator_name)
  }

  calculable period: :month, at: :measured_at, column: :measure_value_value

  before_validation do
    self.measured_at ||= Time.now
  end

end
