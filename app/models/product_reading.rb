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
# == Table: product_readings
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
#  originator_id                :integer
#  originator_type              :string
#  point_value                  :geometry({:srid=>4326, :type=>"point"})
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
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :absolute_measure_value_unit, :choice_value, :originator_type, length: { maximum: 500 }, allow_blank: true
  validates :absolute_measure_value_value, :decimal_value, :measure_value_value, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  validates :boolean_value, inclusion: { in: [true, false] }
  validates :indicator_datatype, :indicator_name, :product, presence: true
  validates :integer_value, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :read_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :string_value, length: { maximum: 100_000 }, allow_blank: true
  # ]VALIDATORS]

  scope :between, lambda { |started_at, stopped_at|
    where(read_at: started_at..stopped_at)
  }
  scope :measured_between, ->(started_at, stopped_at) { between(started_at, stopped_at) }
  scope :of_products, lambda { |products, indicator_name, at = nil|
    at ||= Time.zone.now
    where("id IN (SELECT p1.id FROM #{indicator_table_name(indicator_name)} AS p1 LEFT OUTER JOIN #{indicator_table_name(indicator_name)} AS p2 ON (p1.product_id = p2.product_id AND p1.indicator_name = p2.indicator_name AND (p1.read_at < p2.read_at OR (p1.read_at = p2.read_at AND p1.id < p2.id)) AND p2.read_at <= ?) WHERE p1.read_at <= ? AND p1.product_id IN (?) AND p1.indicator_name = ? AND p2 IS NULL)", at, at, products.pluck(:id), indicator_name)
  }

  calculable period: :month, at: :read_at, column: :measure_value_value

  before_validation(on: :create) do
    self.originator_type = originator.class.base_class.name if originator
    if product && product.initial_born_at
      self.read_at ||= product.initial_born_at
    end
  end

  validate do
    if product && product.born_at
      if self.read_at < product.born_at
        errors.add(:read_at, :posterior, to: product.born_at)
      end
    end
  end
end
