# = Informations
#
# == License
#
# Ekylibre ERP - Simple agricultural ERP
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
# == Table: outgoing_delivery_items
#
#  container_id :integer
#  created_at   :datetime         not null
#  creator_id   :integer
#  delivery_id  :integer          not null
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  net_mass     :decimal(19, 4)
#  population   :decimal(19, 4)
#  product_id   :integer          not null
#  sale_item_id :integer
#  shape        :spatial({:srid=>
#  updated_at   :datetime         not null
#  updater_id   :integer
#


class OutgoingDeliveryItem < Ekylibre::Record::Base
  attr_readonly :sale_item_id, :product_id
  belongs_to :container, class_name: "Product"
  belongs_to :delivery, class_name: "OutgoingDelivery", inverse_of: :items
  belongs_to :product
  belongs_to :sale_item
  has_one :category, through: :variant
  has_one :product_ownership, as: :originator, dependent: :destroy
  has_one :variant, through: :product
  has_many :interventions, class_name: "Intervention", :as => :ressource
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :net_mass, :population, allow_nil: true
  validates_presence_of :delivery, :product
  #]VALIDATORS]

  delegate :net_mass, to: :product

  sums :delivery, :items, :net_mass, from: :measure

  before_validation do
    if self.product
      self.population = self.product.population
      self.shape = self.product.shape if self.product.shape
    end
    true
  end
  
  after_create do
    if self.delivery.done?
      self.create_product_ownership!(product_id: self.product_id, started_at: self.delivery.sent_at, owner_id: self.delivery.recipient_id)
    end
  end
  
  after_update do
    if self.delivery.done?
      self.product_ownership.update_attributes!(product_id: self.product_id, started_at: self.delivery.sent_at, owner_id: self.delivery.recipient_id)
    else
      self.product_ownership.destroy!
    end
  end
  
  # validate(on: :create) do
  #   if self.source_product
  #     maximum = self.source_product.population || 0
  #     errors.add(:population, :greater_than_undelivered_quantity, :maximum => maximum, :unit => self.source_product.variant.unit_name, :product => self.source_product_name) if (self.population > maximum)
  #   end
  #   true
  # end

  # validate(on: :update) do
  #   old_self = self.old_record
  #   maximum = self.product.population || 0
  #   errors.add(:population, :greater_than_undelivered_quantity, :maximum => maximum, :unit => self.product.variant.unit_name, :product => self.product_name) if (self.population > maximum)
  # end

  # def undelivered_quantity
  #  self.sale_item.undelivered_quantity
  # end

  def source_product_name
    self.source_product.name
  end

end
