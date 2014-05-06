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
# == Table: incoming_delivery_items
#
#  container_id     :integer
#  created_at       :datetime         not null
#  creator_id       :integer
#  delivery_id      :integer          not null
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  population       :decimal(19, 4)   default(1.0), not null
#  product_id       :integer          not null
#  purchase_item_id :integer
#  updated_at       :datetime         not null
#  updater_id       :integer
#


class IncomingDeliveryItem < Ekylibre::Record::Base
  attr_readonly :purchase_item_id, :product_id
  attr_accessor :product_nature_variant_id
  belongs_to :delivery, class_name: "IncomingDelivery", inverse_of: :items
  belongs_to :container, class_name: "Product"
  belongs_to :product
  belongs_to :purchase_item, class_name: "PurchaseItem"
  has_one :variant, through: :product
  has_one :product_localization, as: :originator
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :population, allow_nil: true
  validates_presence_of :delivery, :population, :product
  #]VALIDATORS]
  validates_presence_of :product, :container

  accepts_nested_attributes_for :product
  acts_as_stockable :origin => :delivery
  delegate :variant, :name, to: :product, prefix: true

  before_validation(on: :create) do
    if self.product
      self.population = -999999
    end
  end

  after_create do
    # all indicators have the datetime of the receive delivery
    self.product.readings.update_all(read_at: self.delivery.received_at)
    self.create_product_localization!(product: self.product, container: self.container, nature: :interior, started_at: self.delivery.received_at)
  end

  after_save do
    self.update_column(:population, self.product.population)
  end

end
