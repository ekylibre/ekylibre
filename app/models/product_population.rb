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
