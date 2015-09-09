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
# == Table: incoming_parcel_items
#
#  container_id     :integer
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  lock_version     :integer          default(0), not null
#  net_mass         :decimal(19, 4)
#  parcel_id        :integer          not null
#  population       :decimal(19, 4)
#  product_id       :integer          not null
#  purchase_item_id :integer
#  shape            :geometry({:srid=>4326, :type=>"geometry"})
#  updated_at       :datetime         not null
#  updater_id       :integer
#

class IncomingParcelItem < Ekylibre::Record::Base
  attr_readonly :product_id
  attr_accessor :product_nature_variant_id
  belongs_to :parcel, class_name: 'IncomingParcel', inverse_of: :items
  belongs_to :container, class_name: 'Product'
  belongs_to :product
  belongs_to :purchase_item, class_name: 'PurchaseItem'
  has_one :variant, through: :product
  has_one :product_localization, as: :originator
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :net_mass, :population, allow_nil: true
  validates_presence_of :parcel, :product
  # ]VALIDATORS]
  validates_presence_of :product, :container

  accepts_nested_attributes_for :product
  delegate :variant, :name, to: :product, prefix: true

  before_validation(on: :create) do
    self.population = -999_999 if product
  end

  after_create do
    # all indicators have the datetime of the receive parcel
    product.readings.update_all(read_at: parcel.received_at)
    self.create_product_localization!(product: product, container: container, nature: :interior, started_at: parcel.received_at)
  end

  after_save do
    update_column(:population, product.population)
  end
end
