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
# == Table: intervention_parameters
#
#  assembly_id              :integer
#  component_id             :integer
#  created_at               :datetime         not null
#  creator_id               :integer
#  currency                 :string
#  event_participation_id   :integer
#  group_id                 :integer
#  id                       :integer          not null, primary key
#  intervention_id          :integer          not null
#  lock_version             :integer          default(0), not null
#  new_container_id         :integer
#  new_group_id             :integer
#  new_name                 :string
#  new_variant_id           :integer
#  outcoming_product_id     :integer
#  position                 :integer          not null
#  product_id               :integer
#  quantity_handler         :string
#  quantity_indicator_name  :string
#  quantity_population      :decimal(19, 4)
#  quantity_unit_name       :string
#  quantity_value           :decimal(19, 4)
#  reference_name           :string           not null
#  type                     :string
#  unit_pretax_stock_amount :decimal(19, 4)   default(0.0), not null
#  updated_at               :datetime         not null
#  updater_id               :integer
#  variant_id               :integer
#  working_zone             :geometry({:srid=>4326, :type=>"multi_polygon"})
#

# An intervention input represents a product which is used and "consumed" by the
# intervention. The input is divided from a source product. Its tracking number
# follows the new product.
class InterventionInput < InterventionProductParameter
  belongs_to :intervention, inverse_of: :inputs
  belongs_to :outcoming_product, class_name: 'Product'
  has_one :product_movement, as: :originator, dependent: :destroy
  validates :quantity_population, :product, presence: true
  # validates :component, presence: true, if: -> { reference.component_of? }

  scope :of_component, -> (component) { where(component: component.self_and_parents) }

  before_validation do
    self.variant = product.variant if product
  end

  after_save do
    if product && intervention.record?
      movement = product_movement ||
                 build_product_movement(product: product)
      movement.delta = -1 * quantity_population
      movement.started_at = intervention.started_at || Time.zone.now - 1.hour
      movement.stopped_at = intervention.stopped_at || movement.started_at + 1.hour
      movement.save!
    end
  end

  def stock_amount
    quantity_population * unit_pretax_stock_amount
  end

  def cost_amount_computation
    return InterventionParameter::AmountComputation.failed unless product
    incoming_parcel = product.incoming_parcel_item
    options = { quantity: quantity_population, unit_name: product.unit_name }
    if incoming_parcel && incoming_parcel.purchase_item
      options[:purchase_item] = incoming_parcel.purchase_item
      return InterventionParameter::AmountComputation.quantity(:purchase, options)
    else
      options[:catalog_usage] = :purchase
      options[:catalog_item] = product.default_catalog_item(options[:catalog_usage])
      return InterventionParameter::AmountComputation.quantity(:catalog, options)
    end
  end
end
