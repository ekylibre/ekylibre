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

# An intervention input represents a product which is used and "consumed" by the
# intervention. The input is divided from a source product. Its tracking number
# follows the new product.
class InterventionInput < InterventionProductParameter
  CONCENTRATION_HANDLER = %w[specific_weight volume_density].freeze

  belongs_to :intervention, inverse_of: :inputs
  belongs_to :outcoming_product, class_name: 'Product'
  belongs_to :usage, class_name: 'RegisteredPhytosanitaryUsage'
  has_one :product_movement, as: :originator, dependent: :destroy
  has_one :pfi_input, -> { where(nature: 'intervention') }, class_name: 'PfiInterventionParameter', foreign_key: :input_id, dependent: :destroy
  has_many :pfi_inputs, -> { where(nature: 'crop') }, class_name: 'PfiInterventionParameter', foreign_key: :input_id, dependent: :destroy
  validates :quantity_population, :product, presence: true
  validates :spray_volume_value, presence: true, if: -> { CONCENTRATION_HANDLER.include?(quantity_handler)}

  # validates :component, presence: true, if: -> { reference.component_of? }

  scope :of_component, ->(component) { where(component: component.self_and_parents) }
  scope :of_maaids, ->(*maaids) { joins(:variant).where('product_nature_variants.france_maaid IN (?)', maaids)}

  before_validation(on: :create) do
    if self.product.present? && (phyto = self.product.phytosanitary_product).present? && using_live_data
      self.allowed_entry_factor = phyto.in_field_reentry_delay
    end
    if self.usage.present? && using_live_data
      self.allowed_harvest_factor = self.usage.pre_harvest_delay
      self.applications_frequency = self.usage.applications_frequency
    end
  end

  before_validation do
    self.variant = product.variant if product
    assign_reference_data if product && usage && using_live_data
    true
  end

  after_save do
    if product && intervention.record?
      movement = product_movement ||
                 build_product_movement(product: product)
      movement.product = product
      movement.delta = -1 * quantity_population
      movement.started_at = intervention.started_at || Time.zone.now - 1.hour
      movement.stopped_at = intervention.stopped_at || movement.started_at + 1.hour
      movement.save!
    end
  end

  # @param [Onoma::Item<Unit>] target_unit
  # @param [Measure<area>] area
  def input_quantity_per_area(target_unit: nil, area: nil)
    if Onoma::Unit.find(quantity.unit).dimension == :none
      quantity
    else
      converter = Interventions::ProductUnitConverter.new
      quantity_base_unit = Onoma::Unit.find(quantity.unit).base_unit.to_s

      target_unit_into = target_unit || Onoma::Unit.find(quantity_base_unit + '_per_hectare')
      area_into = Maybe(area).or_else(Maybe(intervention.working_zone_area))

      params = {
        into: target_unit_into,
        area: area_into,
        net_mass: Maybe(product.net_mass),
        net_volume: Maybe(product.net_volume),
        spray_volume: None()
      }

      converter.convert(quantity, **params).or_else(quantity)
    end
  end

  # from EPHY
  def reglementary_status(target)
    dose = quantity.convert(:liter_per_hectare)

    # if AMM number on product
    if variant.france_maaid

      # get agent if exist
      agent = Pesticide::Agent.find(variant.france_maaid)

      reglementary_doses = {}

      if agent.usages.any?
        # for each usages matching variety, get data in reglementary_doses hash
        agent.usages.each_with_index do |usage, index|
          next unless usage.subject_variety && usage.dose

          # get variables
          activity_variety = target.product.variety
          activity_variety ||= target.best_activity_production.cultivation_variety if target.best_activity_production
          uv = Onoma::Variety[usage.subject_variety.to_sym]

          next unless activity_variety && (uv >= Onoma::Variety[activity_variety.to_sym])

          reglementary_doses[index] = {}
          reglementary_doses[index][:name] = usage.name.to_s.downcase
          reglementary_doses[index][:variety] = uv.l
          reglementary_doses[index][:level] = :activity_variety
          reglementary_doses[index][:legal_dose] = usage.dose
          reglementary_doses[index][:max_inputs_count] = usage.max_inputs_count
          reglementary_doses[index][:untreated_zone_margin] = usage.untreated_zone_margin
          reglementary_doses[index][:pre_harvest_interval] = usage.pre_harvest_interval
          if usage.dose.is_a?(Measure) && quantity.is_a?(Measure) && usage.dose.dimension == :volume_area_density
            if usage.dose.convert(:liter_per_hectare) < quantity.convert(:liter_per_hectare)
              reglementary_doses[index][:status] = :stop
            elsif usage.dose.convert(:liter_per_hectare) == quantity.convert(:liter_per_hectare)
              reglementary_doses[index][:status] = :caution
            elsif usage.dose.convert(:liter_per_hectare) > quantity.convert(:liter_per_hectare)
              reglementary_doses[index][:status] = :go
            end
          end
        end
      end
      # puts reglementary_doses.inspect.green

      reglementary_doses

    end
  end

  def stock_amount
    quantity_population * unit_pretax_stock_amount
  end

  def cost_amount_computation(nature: nil, natures: {})
    return InterventionParameter::AmountComputation.failed unless product

    reception_item = product.incoming_parcel_item_storing
    options = { quantity: quantity_population, unit_name: product.conditioning_unit.name, unit: product.conditioning_unit }
    # if reception item link to purchase item, grab amount from purchase item
    if reception_item && reception_item.parcel_item && reception_item.parcel_item.purchase_invoice_item
      options[:purchase_item] = reception_item.parcel_item.purchase_invoice_item
      return InterventionParameter::AmountComputation.quantity(:purchase, options)
    # elsif reception item link to order item, grab amount from order item
    elsif reception_item && reception_item.parcel_item && reception_item.parcel_item.purchase_order_item
      options[:order_item] = reception_item.parcel_item.purchase_order_item
      return InterventionParameter::AmountComputation.quantity(:order, options)
    # grab amount from default purchase catalog item at intervention started_at
    else
      options[:catalog_usage] = :purchase
      options[:catalog_item] = product.default_catalog_item(options[:catalog_usage], started_at, options[:unit])
      return InterventionParameter::AmountComputation.quantity(:catalog, options)
    end
  end

  def non_treatment_area
    if reference_data['usage'].present?
      reference_data['usage']['untreated_buffer_aquatic']
    elsif usage.present?
      usage.untreated_buffer_aquatic
    else
      nil
    end
  end

  private

    def assign_reference_data
      assign_usage_reference_data
      assign_product_reference_data
      self.reference_data['updated_on'] = Date.today
      self.using_live_data = false
    end

    def assign_usage_reference_data
      self.reference_data['usage'] = usage.attributes.slice(*InterventionParameter::LoggedPhytosanitaryUsage::ATTRIBUTES.map(&:to_s))
      self.reference_data['usage']['in_field_reentry_delay'] = usage.product[:in_field_reentry_delay]
      self.reference_data['usage']['france_maaid'] = usage.france_maaid
    end

    def assign_product_reference_data
      return unless phyto = product.phytosanitary_product

      self.reference_data['product'] = phyto.attributes.slice(*InterventionParameter::LoggedPhytosanitaryProduct::ATTRIBUTES.map(&:to_s))
    end
end
