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

  scope :destroyable,             ->          {  }
  scope :chain,                   ->(product) { where(product: product).order(started_at: :asc) }
  scope :initial_population_for,  ->(product) { chain(product).first }
  scope :at,                      ->(time)    { where(started_at: time) }
  scope :before,                  ->(time)    { where(arel_table[:started_at].lt(time)) }
  scope :after,                   ->(time)    { where(arel_table[:started_at].gt(time)) }
  scope :last_before,             ->(time)    { before(time).reorder(started_at: :desc).limit(1) }
  scope :first_after,             ->(time)    { after(time).reorder(started_at: :asc).limit(1) }
  scope :before_with,             ->(time)    { where(arel_table[:started_at].lteq(time)) }
  scope :after_with,              ->(time)    { where(arel_table[:started_at].gteq(time)) }

  validate do
    errors.add(:value, :invalid) if movements.none?
  end

  # More performance.
  def self.compute_values_for!(product)
    chain(product).find_each(&:compute_value)
  end

  def compute_value
    update(value: movements.sum(:delta) + Maybe(previous_population).value.or_else(0))
  end

  def impact_delta(delta)
    self.class.destroyables.destroy_all
    self.class.after_with(started_at).update_all("value = value + #{delta}")
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

  def self.destroyables
    movement_table = ProductMovement.arel_table
    ProductPopulation
      .where(
        movement_table.where(
          movement_table[:product_id].eq(arel_table[:product_id])
          .and(
            movement_table[:started_at].eq(arel_table[:started_at])
          )
        ).exists.not
      )
  end
end
