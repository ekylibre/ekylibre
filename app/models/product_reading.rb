# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
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
# == Table: product_readings
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
#  originator_id                :integer
#  originator_type              :string(255)
#  point_value                  :spatial({:srid=>
#  product_id                   :integer          not null
#  read_at                      :datetime         not null
#  string_value                 :text
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#


class ProductReading < Ekylibre::Record::Base
  include ReadingStorable, PeriodicCalculable
  belongs_to :product, inverse_of: :readings
  belongs_to :originator, polymorphic: true
  has_one :variant, through: :product
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :read_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :integer_value, allow_nil: true, only_integer: true
  validates_numericality_of :absolute_measure_value_value, :decimal_value, :measure_value_value, allow_nil: true
  validates_length_of :absolute_measure_value_unit, :choice_value, :indicator_datatype, :indicator_name, :measure_value_unit, :originator_type, allow_nil: true, maximum: 255
  validates_inclusion_of :boolean_value, in: [true, false]
  validates_presence_of :indicator_datatype, :indicator_name, :product, :read_at
  #]VALIDATORS]

  scope :between, lambda { |started_at, stopped_at|
    where(read_at: started_at..stopped_at)
  }
  scope :measured_between, lambda { |started_at, stopped_at| between(started_at, stopped_at) }
  scope :of_products, lambda { |products, indicator_name, at = nil|
    at ||= Time.now
    where("id IN (SELECT p1.id FROM #{self.indicator_table_name(indicator_name)} AS p1 LEFT OUTER JOIN #{self.indicator_table_name(indicator_name)} AS p2 ON (p1.product_id = p2.product_id AND p1.indicator_name = p2.indicator_name AND (p1.read_at < p2.read_at OR (p1.read_at = p2.read_at AND p1.id < p2.id)) AND p2.read_at <= ?) WHERE p1.read_at <= ? AND p1.product_id IN (?) AND p1.indicator_name = ? AND p2 IS NULL)", at, at, products.pluck(:id), indicator_name)
  }

  calculable period: :month, at: :read_at, column: :measure_value_value

  before_validation(on: :create) do
    if self.originator
      self.originator_type = self.originator.class.base_class.name
    end
    if self.product and self.product.initial_born_at
      self.read_at ||= self.product.initial_born_at
    end
  end

end
