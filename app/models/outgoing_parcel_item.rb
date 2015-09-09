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
# == Table: outgoing_parcel_items
#
#  container_id      :integer
#  created_at        :datetime         not null
#  creator_id        :integer
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  net_mass          :decimal(19, 4)
#  parcel_id         :integer          not null
#  parted            :boolean          default(FALSE), not null
#  parted_product_id :integer
#  population        :decimal(19, 4)
#  product_id        :integer          not null
#  sale_item_id      :integer
#  shape             :geometry({:srid=>4326, :type=>"geometry"})
#  updated_at        :datetime         not null
#  updater_id        :integer
#

class OutgoingParcelItem < Ekylibre::Record::Base
  attr_readonly :sale_item_id, :product_id
  belongs_to :container, class_name: 'Product'
  belongs_to :parcel, class_name: 'OutgoingParcel', inverse_of: :items
  belongs_to :product
  belongs_to :parted_product, class_name: 'Product'
  belongs_to :sale_item
  has_one :category, through: :variant
  has_one :product_ownership, as: :originator, dependent: :destroy
  has_one :product_division, as: :originator, dependent: :destroy, class_name: 'ProductJunction'
  has_one :recipient, through: :parcel
  has_one :variant, through: :product
  has_many :interventions, class_name: 'Intervention', as: :resource
  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :net_mass, :population, allow_nil: true
  validates_inclusion_of :parted, in: [true, false]
  validates_presence_of :parcel, :product
  # ]VALIDATORS]

  delegate :sent_at, to: :parcel

  sums :parcel, :items, :net_mass, from: :measure

  before_validation do
    if product
      self.population ||= product.population
      self.shape ||= product.shape if product.shape
    end
    true
  end

  # Create product ownership and division linked to product
  before_save do
    if parcel.done?
      attributes = {
        product_id: product_id,
        started_at: sent_at,
        owner_id: recipient.id
      }
      if product_ownership
        product_ownership.update_attributes!(attributes)
      else
        self.create_product_ownership!(attributes)
      end
      if parted
        if parted_product
          parted_product.initial_population = self.population
          parted_product.initial_shape = self.shape
          parted_product.initial_born_at = sent_at
          parted_product.save!
        else
          self.parted_product = product.part_with!(self.population, shape: self.shape, born_at: sent_at)
        end
        separated = parted_product
        reduced = product
        attributes = {
          nature: :division,
          started_at: sent_at,
          ways_attributes: [
            { role: :separated, product: separated },
            { role: :reduced, product: reduced }
          ]
        }
        if product_division
          product_division.update_attributes!(attributes)
        else
          self.create_product_division!(attributes)
        end

        # FIXME: Copied from Operation#perform_division

        # Duplicate individual indicator data
        separated.copy_readings_of!(reduced, at: sent_at, originator: product_division)

        # Impact on following readings
        reduced.substract_and_read(self, at: sent_at, originator: product_division)

      end
    else
      product_ownership.destroy! if product_ownership
      product_division.destroy! if product_division
    end
  end

  def net_mass
    object = (parted ? parted_product : product)
    return (object ? object.net_mass : 0.in_kilogram)
  end
end
