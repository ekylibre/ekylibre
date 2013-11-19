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
# == Table: product_indicator_data
#
#  boolean_value       :boolean          not null
#  choice_value        :string(255)
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
#  measured_at         :datetime         not null
#  move_id             :integer
#  move_type           :string(255)
#  multi_polygon_value :spatial({:srid=>
#  operation_task_id   :integer
#  point_value         :spatial({:srid=>
#  product_id          :integer          not null
#  string_value        :text
#  updated_at          :datetime         not null
#  updater_id          :integer
#


class ProductIndicatorDatum < IndicatorDatum
  # attr_accessible :created_at, :product_id, :measured_at, :description
  belongs_to :product
  belongs_to :operation_task

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  #]VALIDATORS]

  scope :measured_between, lambda { |started_on, stopped_on|
    where("measured_at BETWEEN ? AND ?", started_on, stopped_on)
  }

  def self.averages_of_periods(column = :valeur, reference_date_column = :measured_at, period = :month, dtype = :measure_value)
    self.calculate_in_periods(:avg, column, reference_date_column, period, dtype)
  end

  def self.sums_of_periods(column = :valeur, reference_date_column = :measured_at, period = :month, dtype = :measure_value)
    self.calculate_in_periods(:sum, column, reference_date_column, period, dtype)
  end

  def self.counts_of_periods(dtype = :measure_value, column = :valeur, reference_date_column = :measured_at, period = :month)
    self.calculate_in_periods(:count, column, reference_date_column, period, dtype)
  end

  # @TODO update method with list of indicator datatype
  def self.calculate_in_periods(operation, column, reference_date_column, period = :month, dtype = :measure_value)
    ind_val = dtype.to_s + '_value'
    period = :doy if period == :day
    expr = "EXTRACT(YEAR FROM #{reference_date_column})*1000 + EXTRACT(#{period} FROM #{reference_date_column})"
    group(expr).order(expr).select("#{expr} AS expr, #{operation}(#{ind_val}) AS #{column}")
  end

end
