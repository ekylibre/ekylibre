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
# == Table: product_movements
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  delta           :decimal(19, 4)   not null
#  description     :string
#  id              :integer          not null, primary key
#  intervention_id :integer
#  lock_version    :integer          default(0), not null
#  originator_id   :integer
#  originator_type :string
#  population      :decimal(19, 4)   not null
#  product_id      :integer          not null
#  started_at      :datetime         not null
#  stopped_at      :datetime
#  updated_at      :datetime         not null
#  updater_id      :integer
#

# A product move is a movement of population
class ProductMovement < Ekylibre::Record::Base
  include Taskable
  belongs_to :intervention
  belongs_to :product
  has_one :container, through: :product
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :delta, :population, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  validates :originator_type, length: { maximum: 500 }, allow_blank: true
  validates :started_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }
  validates :stopped_at, timeliness: { on_or_after: ->(product_movement) { product_movement.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :product, presence: true
  # ]VALIDATORS]

  enumerize :description, in: %i[birth purchase loan butchery consumption sale death]

  before_validation do
    # NOTE: -! Deprecated !- only there for it to work until 3.0
    self.population = 0.0
    self.stopped_at = started_at + 1.day if started_at
  end

  def population
    Maybe(product_population).value.or_else(0)
  end

  def product_population
    ProductPopulation.find_by(product_id: product_id, started_at: started_at)
  end
end
