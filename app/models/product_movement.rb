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
# == Table: product_movements
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  delta           :decimal(19, 4)   not null
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
  include Taskable, TimeLineable
  belongs_to :intervention
  belongs_to :product
  has_one :container, through: :product
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: DateTime.civil(1900, 1, 1), on_or_before: -> { DateTime.now + 50.years }
  validates_datetime :stopped_at, allow_blank: true, on_or_after: Proc.new { |a| a.started_at }, if: Proc.new { |a| a.started_at && a.stopped_at }
  validates_numericality_of :delta, :population, allow_nil: true
  validates_presence_of :delta, :population, :product, :started_at
  # ]VALIDATORS]

  before_validation do
    # errors.add(:delta, :invalid) if delta == 0.0
    if delta
      self.population = delta
      self.population += previous.population if previous
    end
  end

  before_update do
    old_record.remove_delta_on_followings
  end

  after_save :add_delta_on_followings
  after_destroy :remove_delta_on_followings

  def remove_delta_on_followings
    impact_on_followings(-delta)
  end

  def add_delta_on_followings
    impact_on_followings(delta)
  end

  private

  def impact_on_followings(quantity)
    followings.update_all("population = population + (#{quantity})")
  end

  def siblings
    product.movements
  end
end
