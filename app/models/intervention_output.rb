# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
#  variant_id               :integer
#  variety                  :string
#  working_zone             :geometry({:srid=>4326, :type=>"multi_polygon"})
#

# An intervention output represents a product which is produced by the
# intervention. The output generate a product with the given quantity.
class InterventionOutput < InterventionProductParameter
  belongs_to :intervention, inverse_of: :outputs
  belongs_to :product, dependent: :destroy
  has_one :product_movement, as: :originator, dependent: :destroy
  validates :variant, :quantity_population, presence: true

  after_save do
    unless destroyed?
      output = product
      output ||= variant.products.new unless output
      output.type = variant.matching_model.name
      output.born_at = intervention.started_at
      output.initial_born_at = output.born_at

      output.name = new_name if !procedure.of_category?(:planting) && new_name.present?
      output.name = compute_output_planting_name if procedure.of_category?(:planting)

      output.identification_number = identification_number if identification_number.present?
      # output.attributes = product_attributes
      reading = readings.find_by(indicator_name: :shape)
      output.initial_shape = reading.value if reading
      output.save!

      if intervention.record?
        movement = product_movement
        movement ||= build_product_movement(product: output)
        movement.delta = quantity_population
        movement.started_at = intervention.started_at if intervention
        movement.started_at ||= Time.zone.now - 1.hour
        movement.stopped_at = intervention.stopped_at if intervention
        movement.stopped_at ||= movement.started_at + 1.hour
        movement.save!
      end

      update_columns(product_id: output.id) # , movement_id: movement.id)
      true
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
    land_parcel_name = group
                       .targets
                       .select { |target| target.product.is_a?(LandParcel) }
                       .first
                       .product
                       .name

    compute_name = [land_parcel_name]

    return output_name_without_params(compute_name) if variety.blank? && batch_number.blank?

    compute_name << variety if variety.present?
    compute_name << batch_number if batch_number.present?

    output_duplicate_count = output_name_count(compute_name.join(' '))

    compute_name << "(#{output_duplicate_count})" unless output_duplicate_count.zero?
    compute_name.join(' ')
  end

  private

  def output_name_without_params(compute_name)
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
