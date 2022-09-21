# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2022 Ekylibre SAS
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
#  allowed_entry_factor     :interval
#  allowed_harvest_factor   :interval
#  applications_frequency   :interval
#  assembly_id              :integer
#  batch_number             :string
#  component_id             :integer
#  created_at               :datetime         not null
#  creator_id               :integer
#  currency                 :string
#  dead                     :boolean          default(FALSE), not null
#  event_participation_id   :integer
#  group_id                 :integer
#  id                       :integer          not null, primary key
#  identification_number    :string
#  imputation_ratio         :decimal(19, 4)   default(1), not null
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
#  reference_data           :jsonb            default("{}")
#  reference_name           :string           not null
#  specie_variety           :jsonb            default("{}")
#  spray_volume_value       :decimal(19, 4)
#  type                     :string
#  unit_pretax_stock_amount :decimal(19, 4)   default(0.0), not null
#  updated_at               :datetime         not null
#  updater_id               :integer
#  usage_id                 :string
#  using_live_data          :boolean          default(TRUE)
#  variant_id               :integer
#  working_zone             :geometry({:srid=>4326, :type=>"multi_polygon"})
#

# This class is used for all intervenants that make the interventions. It
# gathers tools and doers.
class InterventionAgent < InterventionProductParameter
  belongs_to :intervention, inverse_of: :agents
  validates :product, presence: true

  delegate :working_duration, to: :intervention, prefix: true

  # return participation if exist
  def participation
    if product
      participation = InterventionParticipation.find_by(product: product, intervention: intervention)
    end
  end

  def cost_amount_computation(nature: nil, natures: {})
    # compute a unit price for a doer(worker) or an equipment only in time dimension (base unit : second)

    return InterventionParameter::AmountComputation.failed unless product

    quantity = if natures.empty?
                 nature_quantity(nature)
               else
                 natures_quantity(natures)
               end

    unit_name = Onoma::Unit.find(:hour).human_name
    unit_name = unit_name.pluralize if quantity > 1
    # use hour_equipment unit for equipment and hour unit for other (doer, service...)
    unit = self.is_a?(InterventionTool) ? Unit.import_from_lexicon(:hour_equipment) : Unit.import_from_lexicon(:hour_worker)

    # Add computation from worker contract
    current_contract = WorkerContract.active_at(intervention.started_at).where(entity_id: product.person_id)
    current_product_catalog_item = CatalogItem.of_product(product).active_at(intervention.started_at).of_dimension_unit(unit.dimension).reorder('started_at DESC').first
    if current_contract.any?
      options = { quantity: quantity.to_d, unit: unit, unit_name: unit_name, worker_contract_item: current_contract.first }
      InterventionParameter::AmountComputation.quantity(:worker_contract, options)
    # Add computation from worker or equipment product catalog price
    elsif current_product_catalog_item.present?
      options = {
        catalog_usage: catalog_usage,
        catalog_item: current_product_catalog_item,
        quantity: quantity.to_d,
        unit_name: unit_name,
        unit: unit
      }
      InterventionParameter::AmountComputation.quantity(:catalog, options)
    # Add computation from worker or equipment variant catalog price
    else
      usage =
        if nature.present? && nature != :intervention && product.variant.catalog_items.joins(:catalog).where('catalogs.usage': "#{nature}_cost").any?
          "#{nature}_cost"
        else
          catalog_usage
        end

      options = {
        catalog_usage: usage,
        quantity: quantity.to_d,
        unit_name: unit_name,
        unit: unit
      }

      options[:catalog_item] = product.default_catalog_item(options[:catalog_usage], intervention.started_at, options[:unit], :dimension)
      InterventionParameter::AmountComputation.quantity(:catalog, options)
    end
  end

  def working_duration_params
    { intervention: intervention,
      participations: intervention.participations,
      product: product }
  end

  def natures_quantity(natures)
    quantity = 0

    natures.each do |nature|
      quantity += nature_quantity(nature)
    end

    quantity
  end

  def nature_quantity(nature)
    InterventionWorkingTimeDurationCalculationService
      .new(**working_duration_params)
      .perform(nature: nature)
  end

  def catalog_usage
    :cost
  end
end
