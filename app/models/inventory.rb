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
# == Table: inventories
#
#  accounted_at     :datetime
#  achieved_at      :datetime
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  journal_entry_id :integer
#  lock_version     :integer          default(0), not null
#  name             :string           not null
#  number           :string
#  reflected        :boolean          default(FALSE), not null
#  reflected_at     :datetime
#  responsible_id   :integer
#  updated_at       :datetime         not null
#  updater_id       :integer
#

class Inventory < Ekylibre::Record::Base
  include Attachable
  belongs_to :responsible, -> { contacts }, class_name: 'Entity'
  has_many :items, class_name: 'InventoryItem', dependent: :destroy, inverse_of: :inventory
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :accounted_at, :achieved_at, :reflected_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_inclusion_of :reflected, in: [true, false]
  validates_presence_of :name
  # ]VALIDATORS]
  validates_length_of :number, allow_nil: true, maximum: 20
  validates_presence_of :achieved_at

  scope :unreflecteds, -> { where(reflected: false) }
  scope :before, ->(at) { where(arel_table[:achieved_at].lt(at)) }

  accepts_nested_attributes_for :items

  before_validation do
    self.achieved_at ||= Time.zone.now
  end

  bookkeep on: :nothing do |_b|
  end

  protect do
    old_record.reflected?
  end

  def reflectable?
    !reflected? # && self.class.unreflecteds.before(self.achieved_at).empty?
  end

  # Apply deltas on products
  def reflect
    raise StandardError, 'Not reflectable inventory' unless reflectable?
    self.class.transaction do
      self.reflected_at = Time.zone.now
      self.reflected = true
      save!
      items.find_each(&:save)
    end
  end

  def build_missing_items
    self.achieved_at ||= Time.zone.now
    Matter.at(achieved_at).of_owner(Entity.of_company).find_each do |product|
      next if items.detect { |i| i.product_id == product.id }
      population = product.population(at: self.achieved_at)
      # shape = product.shape(at: self.achieved_at)
      items.build(product_id: product.id, actual_population: population, expected_population: population)
    end
  end

  def refresh!
    raise StandardError, 'Cannot refresh uneditable inventory' unless editable?
    items.clear
    build_missing_items
    save!
  end
end
