# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
#  type                     :string
#  unit_pretax_stock_amount :decimal(19, 4)   default(0.0), not null
#  updated_at               :datetime         not null
#  updater_id               :integer
#  usage_id                 :string
#  using_live_data          :boolean          default(TRUE)
#  variant_id               :integer
#  working_zone             :geometry({:srid=>4326, :type=>"multi_polygon"})
#

# An intervention output represents a product which is produced by the
# intervention. The output generate a product with the given quantity.
class InterventionOutput < InterventionProductParameter
  belongs_to :intervention, inverse_of: :outputs
  belongs_to :product, dependent: :destroy
  has_one :product_movement, as: :originator, dependent: :destroy

  alias_attribute :variety, :specie_variety_name

  validates :variant, :quantity_population, presence: true
  validates :identification_number, presence: true, if: ->(output) { output.reference.present? && output.reference.attribute(:identification_number).present? }

  validate do
    # Matter can be changed only if the output is not used elsewhere
    #
    # 'Product_id' can only be changed in 'after_save' callback, so we never see it in 'changed' method except for 2 cases : duplicating a request intervention and changing_state of a request_intervention where 'product_id' is directly duplicated
    next if product.nil? || !variant_id_changed? || product_id_changed?

    # Same protection as for product model but excepting the current intervention parameter
    parameters_from_record_intervention = product
                                            .intervention_product_parameters
                                            .where.not(id: self.id)
                                            .joins(:intervention)
                                            .where("interventions.nature = 'record'")
    protected_from_destroy = product.analyses.exists? || product.issues.exists? || product.parcel_items.exists? || parameters_from_record_intervention.exists?
    errors.add(:variant_id, :already_used) if protected_from_destroy
  end

  after_save do
    next if destroyed?

    is_not_created_from_change_state = id_was.present? || intervention.request_intervention.nil?
    if is_not_created_from_change_state
      output = variant.products.new
      if variant_id_was
        # The only case an output product can be linked to 2 interventions is when the product is linked to the self intervention and the request intervention linked (if there is one)
        if product.intervention_product_parameters.count == 2
          product_movement.destroy!
          product.update!(dead_at: Time.zone.now)
        else
          # Remove link preventing product deletion before destroying it
          product_to_destroy = product
          update_columns(product_id: nil)
          product_to_destroy.reload.destroy!
        end
      end
    else
      output = product
    end

    output.type = variant.matching_model.name
    output.born_at = intervention.started_at
    output.initial_born_at = output.born_at
    output.specie_variety_name = specie_variety_name if procedure.of_category?(:planting) && specie_variety_name.present?

    if implantation?
      output.name = compute_output_planting_name
    elsif new_name.present?
      output.name = new_name
    end

    output.identification_number = identification_number if identification_number.present?
    reading = readings.find_by(indicator_name: :shape)
    output.initial_shape = reading.value if reading
    output.save!

    if intervention.record?
      # movement is found this way because if the movement is destroyed in the condition above, 'product_movement' is still returning an object so it won't create a new one
      movement = ProductMovement.find_by(id: product_movement&.id)
      movement ||= build_product_movement(product: output)
      movement.delta = quantity_population
      movement.started_at = intervention.started_at if intervention
      movement.started_at ||= Time.zone.now - 1.hour
      movement.stopped_at = intervention.stopped_at if intervention
      movement.stopped_at ||= movement.started_at + 1.hour
      movement.save!
    end

    update_columns(product_id: output.id)

    if procedure.of_category?(:planting) && readings.any?
      readings.reject{ |r| r.indicator_name == "shape" }.map do |reading|
        reading.reload.create_product_reading
      end
    end
  end

  def stock_amount
    product_movement ? product_movement.population * unit_pretax_stock_amount : 0
  end

  def earn_amount_computation
    options = { quantity: quantity_population, unit_name: product.unit_name }
    if product
      outgoing_parcel = product.outgoing_parcel_item
      if outgoing_parcel && outgoing_parcel.sale_item
        options[:sale_item] = outgoing_parcel.sale_item
        return InterventionParameter::AmountComputation.quantity(:sale, options)
      else
        options[:catalog_usage] = :sale
        options[:catalog_item] = product.default_catalog_item(options[:catalog_usage])
        return InterventionParameter::AmountComputation.quantity(:catalog, options)
      end
    elsif variant
      options[:catalog_usage] = :sale
      options[:catalog_item] = variant.default_catalog_item(options[:catalog_usage])
      return InterventionParameter::AmountComputation.quantity(:catalog, options)
    else
      return InterventionParameter::AmountComputation.failed
    end
  end

  def compute_output_planting_name
    compute_name = []
    if group && group.targets.any?
      land_parcel = group.targets.detect { |target| target.product.is_a?(LandParcel) }
      compute_name << land_parcel.product.name if land_parcel
    end

    return output_name_without_params(compute_name) if specie_variety_name.blank? && batch_number.blank?

    if specie_variety_name.present?
      compute_name << '|' if procedure.of_category?(:vine_planting)
      compute_name << specie_variety_name
    end
    compute_name << batch_number if batch_number.present?

    output_duplicate_count = output_name_count(compute_name.join(' '))

    compute_name << "(#{output_duplicate_count})" unless output_duplicate_count.zero?
    compute_name.join(' ')
  end

  private

    def implantation?
      procedure.of_category?(:planting) || procedure.of_category?(:vine_planting)
    end

    def output_name_without_params(compute_name)
      compute_name << '|' if procedure.of_category?(:vine_planting)
      compute_name << variant.name
      output_duplicate_count = output_name_count(compute_name.join(' '))

      rank_number = I18n.t('labels.number_with_param', number: output_duplicate_count + 1)
      compute_name << rank_number.downcase

      compute_name.join(' ')
    end

    def output_name_count(name)
      Plant.where('name like ?', "%#{Regexp.escape(name)}%").count
    end
end
