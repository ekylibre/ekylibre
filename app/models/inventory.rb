# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: inventories
#
#  accounted_at     :datetime
#  achieved_at      :datetime
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  journal_entry_id :integer
#  lock_version     :integer          default(0), not null
#  name             :string(255)      not null
#  number           :string(20)
#  reflected        :boolean          not null
#  reflected_at     :datetime
#  responsible_id   :integer
#  updated_at       :datetime         not null
#  updater_id       :integer
#


class Inventory < Ekylibre::Record::Base
  belongs_to :responsible, class_name: "Person"
  has_many :items, class_name: "InventoryItem", dependent: :destroy, inverse_of: :inventory
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :number, allow_nil: true, maximum: 20
  validates_length_of :name, allow_nil: true, maximum: 255
  validates_inclusion_of :reflected, in: [true, false]
  validates_presence_of :name
  #]VALIDATORS]
  validates_presence_of :achieved_at

  scope :unreflecteds, -> { where(reflected: false) }

  accepts_nested_attributes_for :items

  before_validation do
    self.achieved_at ||= Time.now
  end

  bookkeep on: :nothing do |b|
  end

  protect do
    self.old_record.reflected?
  end

  def reflectable?
    !self.reflected? and self.class.unreflecteds.where(self.class.arel_table[:achieved_at].lt(self.achieved_at)).empty?
  end

  # Apply deltas on products
  def reflect
    unless self.reflectable?
      raise StandardError, "Cannot reflect reflected inventory"
    end
    self.class.transaction do
      self.reflected_at = Time.now
      self.reflected = true
      self.save!
      for item in self.items
        if item.actual_population != item.expected_population and product = item.product
          delta = item.actual_population - item.expected_population

          # Adds reading now if not found before
          product.read!(:population, item.actual_population, at: self.achieved_at, originator: item)

          # Updates
          for reading in product.readings.where(indicator_name: "population").where("read_at > ?", self.achieved_at)
            reading.value += delta
            reading.save!
          end
        end
      end
    end
  end

  def build_missing_items
    self.achieved_at ||= Time.now
    for product in Matter.at(achieved_at).of_owner(Entity.of_company)
      unless self.items.detect{|i| i.product_id == product.id }
        population = product.population(at: self.achieved_at)
        # shape = product.shape(at: self.achieved_at)
        self.items.build(product_id: product.id, actual_population: population, expected_population: population)
      end
    end
  end

  def refresh!
    unless self.editable?
      raise StandardError, "Cannot refresh uneditable inventory"
    end
    self.items.clear
    self.build_missing_items
    self.save!
  end

end
