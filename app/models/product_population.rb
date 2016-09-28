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
# == Table: product_populations
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  product_id   :integer
#  started_at   :datetime         not null
#  stopped_at   :datetime
#  updated_at   :datetime         not null
#  updater_id   :integer
#  value        :decimal(19, 4)
#

# Sum of all the deltas in product movements up to and including a date.
class ProductPopulation < Ekylibre::Record::Base
  belongs_to :product
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :started_at, uniqueness: { scope: :product_id }
  validates :started_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :stopped_at, timeliness: { on_or_after: ->(product_population) { product_population.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :value, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }, allow_blank: true
  # ]VALIDATORS]

  scope :chain,                   ->(product) { where(product: product).order(started_at: :asc) }
  scope :initial_population_for,  ->(product) { chain(product).first }
  scope :at,                      ->(time)    { where(started_at: time) }
  scope :last_before,             ->(time)    { where(arel_table[:started_at].lt(time)).reorder(started_at: :desc).limit(1) }
  scope :first_after,             ->(time)    { where(arel_table[:started_at].gt(time)).reorder(started_at: :asc).limit(1) }

  validate do
    errors.add(movements, :invalid) if movements.none?
  end

  # More performance.
  def self.compute_values_for!(product)
    chain(product).find_each(&:compute_value!)
  end

  def compute_value!(impact_on_following: false)
    return destroy if movements.none?

    update(value: movements.sum(:delta) + Maybe(previous_population).value.or_else(0))

    if following_population.present?
      update(stopped_at: following_population.started_at)
      following_population.compute_value!(impact_on_following: impact_on_following) if impact_on_following
    end
  end

  def chain
    self.class.chain(product)
  end

  def siblings
    chain.where.not(id: id)
  end

  def previous_population
    siblings.last_before(started_at).first
  end

  def following_population
    siblings.first_after(started_at).first
  end

  def movements
    ProductMovement.where(product: product, started_at: started_at)
  end
end
