# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
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
    self.reflected?
  end

  def reflectable?
    !self.reflected? and self.class.unreflecteds.where(self.class.arel_table[:created_at].lt(self.created_at)).empty?
  end

  # Apply deltas on products ?
  def reflect
    self.reflected_at = Time.now
    self.reflected = true
    for item in self.items
      # item.confirm_stock_move(reflected_at)
    end
    self.save
  end

  def build_missing_items
    self.achieved_at ||= Time.now
    for product in Product.at(achieved_at).of_owner(Entity.of_company)
      unless self.items.find_by(product_id: product.id)
        self.items.build(product_id: product.id, population: product.population(at: self.achieved_at), theoric_population: product.population(at: self.achieved_at))
      end
    end
  end

end
