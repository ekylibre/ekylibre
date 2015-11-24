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
# == Table: product_junction_ways
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  junction_id  :integer          not null
#  lock_version :integer          default(0), not null
#  nature       :string           not null
#  product_id   :integer          not null
#  role         :string           not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#
class ProductJunctionWay < Ekylibre::Record::Base
  attr_readonly :nature
  belongs_to :junction, class_name: 'ProductJunction', inverse_of: :ways
  belongs_to :product, inverse_of: :junction_ways, class_name: 'Product'
  enumerize :nature, in: [:start, :continuity, :finish], predicates: true
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_presence_of :junction, :nature, :product, :role
  # ]VALIDATORS]
  validates_inclusion_of :nature, in: nature.values

  delegate :started_at, :stopped_at, to: :junction
  delegate :nature, to: :junction, prefix: true
  delegate :variant, to: :product, prefix: true

  before_validation do
    if junction && nature.blank? && role
      reflection = junction.reflect_on(role)
      self.nature = reflection.type if reflection
    end
  end

  before_update do
    unless self.continuity?
      if product_id != old_record.product_id
        old_record.product.update_column(touch_column, nil)
      end
    end
  end

  validate do
    if junction
      reflection = junction.reflect_on(role)
      if reflection
      # TODO: check cardinality
      else
        errors.add(:role, :invalid)
      end
    end
  end

  after_save do
    unless self.continuity?
      if stopped_at != product.send(touch_column)
        product.update_column(touch_column, stopped_at)
      end
      if self.start?
        # Sets frozen and given indicators
        product_variant.readings.each do |reading|
          product.read!(reading.indicator_name, reading.value, at: stopped_at, force: true)
        end
      end
    end
  end

  before_destroy do
    old_record.product.update_column(touch_column, nil) unless self.continuity?
  end

  # Returns the column to impact on
  def touch_column
    (self.start? ? :born_at : self.finish? ? :dead_at : nil)
  end
end
