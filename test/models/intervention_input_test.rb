# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
#  assembly_id              :integer(4)
#  batch_number             :string
#  component_id             :integer(4)
#  created_at               :datetime         not null
#  creator_id               :integer(4)
#  currency                 :string
#  dead                     :boolean          default(FALSE), not null
#  event_participation_id   :integer(4)
#  group_id                 :integer(4)
#  id                       :integer(4)       not null, primary key
#  identification_number    :string
#  imputation_ratio         :decimal(19, 4)   default(1), not null
#  intervention_id          :integer(4)       not null
#  lock_version             :integer(4)       default(0), not null
#  new_container_id         :integer(4)
#  new_group_id             :integer(4)
#  new_name                 :string
#  new_variant_id           :integer(4)
#  outcoming_product_id     :integer(4)
#  position                 :integer(4)       not null
#  product_id               :integer(4)
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
#  updater_id               :integer(4)
#  usage_id                 :string
#  using_live_data          :boolean          default(TRUE)
#  variant_id               :integer(4)
#  working_zone             :geometry({:srid=>4326, :type=>"multi_polygon"})
#  working_zone_area_value  :decimal(19, 4)
#
require 'test_helper'

class InterventionInputTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  setup do
    FinancialYear.delete_all
    fy = create(:financial_year, year: 2022)
    @catalog = Catalog.by_default!('purchase')
    @started_at = Date.parse('15/02/2022').to_time
    @sender = Entity.create!(last_name: 'Reception test')
    @address = @sender.addresses.create!(canal: 'mail', mail_line_1: 'Yolo', mail_line_2: 'Another test')
    @storage = BuildingDivision.first
    @variant = ProductNatureVariant.import_from_lexicon('ammonitrate_33')
    @activity = Activity.find_by(production_cycle: :annual, family: 'plant_farming')
    @campaign = Campaign.of(2022)
    @activity_production = @activity.productions.create!(started_on: '2021-10-01', stopped_on: '2022-08-31', campaign: @campaign, cultivable_zone: CultivableZone.first)
    @land_parcel = @activity_production.support
  end

  test 'check intervention input price computation from catalog when reception item is zero price' do
    price = 0.35
    new_catalog_price(price: price)
    reception = new_reception(price: 0.0, quantity: 200.0)
    reception.give
    reception.reload
    fertilizer_product = reception.items.first.storings.first.product
    intervention = new_fertilizing_intervention(fertilizer_product, 500.0)
    intervention.reload
    computation = intervention.inputs.first.cost_amount_computation
    assert_equal true, computation.quantity?
    assert_equal true, computation.catalog?
    assert_equal price, computation.unit_amount
  end

  test 'check intervention input price computation from reception when reception item is not zero price' do
    price = 0.35
    new_catalog_price(price: price)
    reception = new_reception(price: 0.50, quantity: 200.0)
    reception.give
    reception.reload
    fertilizer_product = reception.items.first.storings.first.product
    intervention = new_fertilizing_intervention(fertilizer_product, 500.0)
    intervention.reload
    computation = intervention.inputs.first.cost_amount_computation
    assert_equal true, computation.quantity?
    assert_equal true, computation.reception?
    assert_equal 0.50, computation.unit_amount
  end

  private

    def new_reception(delivery_mode: :third, address: nil, sender: nil, separated: nil, items_attributes: nil, storage: nil, price: nil, quantity: nil)
      attributes = {
        delivery_mode: delivery_mode,
        address: address || @address,
        sender: sender || @sender,
        separated_stock: separated,
        given_at: @started_at - 5.days
      }

      items_attributes ||= [{
        # population: 20,
        unit_pretax_stock_amount: price,
        variant: @variant,
        role: :merchandise,
        storings_attributes: [
          {
            conditioning_quantity: quantity,
            storage: @storage,
            conditioning_unit: @variant.guess_conditioning[:unit]
          }
        ]
      }]

      reception = Reception.create!(attributes)
      items_attributes.each do
        reception.items.create!(items_attributes)
      end

      reception
    end

    def new_catalog_price(price: nil)
      @variant.catalog_items.create!(catalog: @catalog, amount: price, unit: @variant.guess_conditioning[:unit], started_at: @started_at - 5.days)
    end

    def new_fertilizing_intervention(fertilizer_product, quantity)
      Intervention.create!(
        procedure_name: :fertilizing,
        working_periods_attributes: {
          '0' => {
            started_at: @started_at,
            stopped_at: @started_at + 4.hours,
            nature: 'intervention'
          }
        },
        targets_attributes: {
          '0' => {
            reference_name: :cultivation,
            product_id: @land_parcel.id,
            dead: false
          }
        },
        inputs_attributes: {
          '0' => {
            reference_name: :fertilizer,
            product_id: fertilizer_product.id,
            quantity_value: quantity,
            quantity_population: quantity,
            quantity_handler: 'net_mass'
          }
        }
      )
    end
end
