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
# == Table: product_junctions
#
#  created_at      :datetime         not null
#  creator_id      :integer
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  nature          :string           not null
#  operation_id    :integer
#  originator_id   :integer
#  originator_type :string
#  started_at      :datetime
#  stopped_at      :datetime
#  tool_id         :integer
#  updated_at      :datetime         not null
#  updater_id      :integer
#
class ProductJunction < Ekylibre::Record::Base
  include Taskable
  NATURES = {
    birth: {
      born: ProductJunction::Reflection.new(:has_one, :born, as: :start)
    },
    production: {
      produced: ProductJunction::Reflection.new(:has_many, :produced, as: :start),
      producer: ProductJunction::Reflection.new(:has_one, :producer)
    },
    division: {
      separated: ProductJunction::Reflection.new(:has_many, :separated, as: :start),
      reduced: ProductJunction::Reflection.new(:has_one, :reduced)
    },
    death: {
      dead: ProductJunction::Reflection.new(:has_many, :dead, as: :finish)
    },
    consumption: {
      consumer: ProductJunction::Reflection.new(:has_one, :consumer),
      consumed: ProductJunction::Reflection.new(:has_many, :consumed, as: :finish)
    },
    merging: {
      absorber: ProductJunction::Reflection.new(:has_one, :absorber),
      absorbed: ProductJunction::Reflection.new(:has_many, :absorbed, as: :finish)
    },
    mixing: {
      mixed: ProductJunction::Reflection.new(:has_many, :mixed, as: :finish),
      produced: ProductJunction::Reflection.new(:has_one, :produced, as: :start)
    }
  }

  belongs_to :tool, class_name: 'Product'
  enumerize :nature, in: NATURES.keys, predicates: true
  has_many :ways, class_name: 'ProductJunctionWay', inverse_of: :junction, foreign_key: :junction_id, dependent: :destroy
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :started_at, :stopped_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_presence_of :nature
  # ]VALIDATORS]
  validates_presence_of :started_at, :stopped_at
  accepts_nested_attributes_for :ways

  before_validation do
    self.started_at ||= Time.zone.now
    self.stopped_at ||= self.started_at
  end

  # Return matching reflection for given role
  def reflect_on(role)
    reflections = NATURES[nature.to_sym]
    return nil unless reflections
    reflections[role.to_sym]
  end
end
