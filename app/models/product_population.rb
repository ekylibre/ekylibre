# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
#  created_at   :datetime
#  creator_id   :integer
#  id           :integer          primary key
#  lock_version :integer
#  product_id   :integer
#  started_at   :datetime
#  updated_at   :datetime
#  updater_id   :integer
#  value        :decimal(, )
#

# Sum of all the deltas in product movements up to and including a date.
class ProductPopulation < Ekylibre::Record::Base
  self.primary_key = 'id'

  belongs_to :product
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :started_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :value, numericality: true, allow_blank: true
  # ]VALIDATORS]

  scope :chain,                   ->(product) { where(product: product).order(started_at: :asc) }
  scope :initial_population_for,  ->(product) { chain(product).first }
  scope :at,                      ->(time)    { where(started_at: time) }
  scope :before,                  ->(time)    { where(arel_table[:started_at].lt(time)) }
  scope :after,                   ->(time)    { where(arel_table[:started_at].gt(time)) }
  scope :last_before,             ->(time)    { before(time).reorder(started_at: :desc).limit(1) }
  scope :first_after,             ->(time)    { after(time).reorder(started_at: :asc).limit(1) }
  scope :before_with,             ->(time)    { where(arel_table[:started_at].lteq(time)) }
  scope :after_with,              ->(time)    { where(arel_table[:started_at].gteq(time)) }

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
