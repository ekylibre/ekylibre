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
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  journal_entry_id :integer
#  lock_version     :integer          default(0), not null
#  number           :string(20)
#  reflected        :boolean          not null
#  reflected_at     :datetime
#  responsible_id   :integer
#  updated_at       :datetime         not null
#  updater_id       :integer
#


class Inventory < Ekylibre::Record::Base
  belongs_to :responsible, class_name: "Entity"
  has_many :items, class_name: "InventoryItem", dependent: :destroy, inverse_of: :inventory
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :number, allow_nil: true, maximum: 20
  validates_inclusion_of :reflected, in: [true, false]
  #]VALIDATORS]

  scope :unreflecteds, -> { where(reflected: false) }

  accepts_nested_attributes_for :items

  bookkeep on: :nothing do |b|
  end

  protect do
    self.reflected?
  end

  def reflectable?
    !self.reflected? and self.class.unreflecteds.where(arel_table[:created_at].lt(self.created_at)).empty?
  end

  def reflect(reflected_at = Time.now)
    self.reflected_at = reflected_at
    self.reflected = true
    for item in self.items
      # item.confirm_stock_move(reflected_at)
    end
    self.save
  end

end
