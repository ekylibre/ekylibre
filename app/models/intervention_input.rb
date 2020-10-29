# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
#  usage_id                 :string
#  variant_id               :integer
#  variety                  :string
#  working_zone             :geometry({:srid=>4326, :type=>"multi_polygon"})
#

# An intervention input represents a product which is used and "consumed" by the
# intervention. The input is divided from a source product. Its tracking number
# follows the new product.
class InterventionInput < InterventionProductParameter
  belongs_to :intervention, inverse_of: :inputs
  belongs_to :outcoming_product, class_name: 'Product'
  belongs_to :usage, class_name: 'RegisteredPhytosanitaryUsage'
  has_one :product_movement, as: :originator, dependent: :destroy
  validates :quantity_population, :product, presence: true
  # validates :component, presence: true, if: -> { reference.component_of? }

  scope :of_component, ->(component) { where(component: component.self_and_parents) }
  scope :of_maaids, ->(*maaids) { joins(:variant).where('product_nature_variants.france_maaid IN (?)', maaids)}

  before_validation do
    self.variant = product.variant if product
  end

  before_validation(on: :create) do 
    if self.product.present? && (phyto = self.product.phytosanitary_product).present?
      self.allowed_entry_factor = phyto.in_field_reentry_delay
    end
    if self.usage.present?
      self.allowed_harvest_factor = self.usage.pre_harvest_delay
    end
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

  def input_quantity_per_area
    if intervention.working_zone_area.to_d > 0.0 && (quantity.dimension == :mass || quantity.dimension == :volume)
      unit = quantity.unit.to_s + '_per_hectare'
      q = (quantity.value.to_f / intervention.working_zone_area.to_f).round(2)
      q_per_hectare = Measure.new(q.to_f, unit.to_sym)
    elsif quantity.dimension == :volume_area_density || quantity.dimension == :mass_area_density
      q_per_hectare = quantity
    end
    q_per_hectare
  end

  # return pfi dose according to Lexicon pfi dataset and maaid number
  def pfi_reference_dose
    dose = nil
    if variant.france_maaid
      act = intervention.activities
      first_production = intervention.activity_productions.first
      harvest_year = first_production.campaign.harvest_year if first_production && first_production.campaign
      crop_code = act.first.production_nature.pfi_crop_code if act.first.production_nature
      maaid = variant.france_maaid
      if crop_code && maaid && harvest_year
        dose = RegisteredPfiDose.where(france_maaid: maaid, crop_id: crop_code, harvest_year: harvest_year, target_id: nil).first
      end
    end
    dose
  end

  # return legal dose according to Lexicon phyto dataset and maaid number
  def legal_pesticide_informations
    pesticide = RegisteredPhytosanitaryProduct.where(france_maaid: variant.france_maaid).first
    if pesticide
      specie = intervention.activity_productions.first.cultivation_variety
      usages = pesticide.usages.of_variety(specie)

      info = {}
      info[:name] = pesticide.proper_name
      info[:usage] = usages.first.target_name['fra'] if usages.first
      info[:dose] = Measure.new(usages.first.dose_quantity, usages.first.dose_unit) if usages.first
      info
    end
  end

  # only case in mass_area_density && volume_area_density in legals
  def legal_treatment_ratio
    ratio = 1.0
    if legal_pesticide_informations[:dose].dimension == :mass_area_density && input_quantity_per_area.dimension == :mass_area_density
      ratio = input_quantity_per_area.convert(legal_pesticide_informations[:dose].unit) / legal_pesticide_informations[:dose].to_d
    elsif legal_pesticide_informations[:dose].dimension == :volume_area_density && input_quantity_per_area.dimension == :volume_area_density
      ratio = input_quantity_per_area.convert(legal_pesticide_informations[:dose].unit) / legal_pesticide_informations[:dose].to_d
    end
    ratio.to_d
  end

  # only case in mass_area_density && volume_area_density in pfi reference
  def pfi_treatment_ratio
    ratio = 1.0
    if pfi_reference_dose && pfi_reference_dose.dose.to_d > 0.0
      if pfi_reference_dose.dose.dimension == :mass_area_density && input_quantity_per_area.dimension == :mass_area_density
        ratio = input_quantity_per_area.convert(pfi_reference_dose.dose.unit) / pfi_reference_dose.dose.to_d
      elsif pfi_reference_dose.dose.dimension == :volume_area_density && input_quantity_per_area.dimension == :volume_area_density
        ratio = input_quantity_per_area.convert(pfi_reference_dose.dose.unit) / pfi_reference_dose.dose.to_d
      end
    end
    ratio.to_d
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
          uv = Nomen::Variety[usage.subject_variety.to_sym]

          next unless activity_variety && (uv >= Nomen::Variety[activity_variety.to_sym])
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
    reception_item = product.incoming_parcel_item
    options = { quantity: quantity_population, unit_name: product.unit_name }
    if reception_item && reception_item.purchase_order_item
      options[:purchase_order_item] = reception_item.purchase_order_item
      return InterventionParameter::AmountComputation.quantity(:purchase, options)
    else
      options[:catalog_usage] = :purchase
      options[:catalog_item] = product.default_catalog_item(options[:catalog_usage])
      return InterventionParameter::AmountComputation.quantity(:catalog, options)
    end
  end
end
