# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
#  total_cost               :decimal(19, 4)
#  type                     :string
#  unit_pretax_stock_amount :decimal(19, 4)   default(0.0), not null
#  updated_at               :datetime         not null
#  updater_id               :integer
#  variant_id               :integer
#  working_zone             :geometry({:srid=>4326, :type=>"multi_polygon"})
#
require 'test_helper'

class InterventionParameterTest < ActiveSupport::TestCase
  test_model_actions

  test 'total_cost columns values in intervention_parameters, interventions and activity_productions' do
    cultivable_zone = create(:cultivable_zone)
    preparation = create(:preparation)
    equipment = create(:equipment)
    purchase_item = create(:purchase_item)
    catalog_item = create(:catalog_item, variant: equipment.variant)
    parcel_item = create(:parcel_item, product: preparation, variant: preparation.variant, purchase_item: purchase_item, population: 1.to_d, product_identification_number: '12345678', product_name: 'Product name')
    activity_production = create(:activity_production, cultivable_zone: cultivable_zone)
    intervention = create(:spraying)
    create(:intervention_working_period, intervention: intervention, started_at: intervention.started_at, stopped_at: intervention.stopped_at, duration: intervention.duration)
    create(:spraying_target, intervention: intervention, product: activity_production.support, working_zone: activity_production.support.initial_shape)
    create(:intervention_input, intervention: intervention, product: preparation, variant: preparation.variant, quantity_population: 10.to_d)
    create(:intervention_tool, intervention: intervention, product: equipment, variant: equipment.variant)

    assert_equal 15_451.5, intervention.parameters.where(type: 'InterventionInput').first.total_cost.to_f

    assert_equal 15_451.5, intervention.total_input_cost.to_f
    assert_equal 50.0, intervention.total_tool_cost.to_f
    assert_equal 0.0, intervention.total_doer_cost.to_f

    assert_equal 15_451.5, intervention.targets.first.product.activity_production.total_input_cost.to_f
    assert_equal 50.0, intervention.targets.first.product.activity_production.total_tool_cost.to_f
    assert_equal 0.0, intervention.targets.first.product.activity_production.total_doer_cost.to_f

    # After updating input quantity
    intervention.parameters.where(type: 'InterventionInput').first.update(quantity_population: 1.to_d)

    assert_equal 1545.15, intervention.parameters.where(type: 'InterventionInput').first.total_cost.to_f

    assert_equal 1545.15, intervention.total_input_cost.to_f
    assert_equal 50.0, intervention.total_tool_cost.to_f
    assert_equal 0.0, intervention.total_doer_cost.to_f

    assert_equal 1545.15, intervention.targets.first.product.activity_production.total_input_cost.to_f
    assert_equal 50.0, intervention.targets.first.product.activity_production.total_tool_cost.to_f
    assert_equal 0.0, intervention.targets.first.product.activity_production.total_doer_cost.to_f

    # After updating intervention working_period
    intervention.working_periods.first.update(started_at: Time.now - 3.hours, stopped_at: Time.now - 1.hour, duration: 7200)

    assert_equal 1545.15, intervention.total_input_cost.to_f
    assert_equal 100.0, intervention.total_tool_cost.to_f
    assert_equal 0.0, intervention.total_doer_cost.to_f

    assert_equal 1545.15, intervention.targets.first.product.activity_production.total_input_cost.to_f
    assert_equal 100.0, intervention.targets.first.product.activity_production.total_tool_cost.to_f
    assert_equal 0.0, intervention.targets.first.product.activity_production.total_doer_cost.to_f

    # After deleting tool from the intervention
    intervention.parameters.where(type: 'InterventionTool').first.destroy

    assert_equal 1545.15, intervention.total_input_cost.to_f
    assert_equal 0.0, intervention.total_tool_cost.to_f
    assert_equal 0.0, intervention.total_doer_cost.to_f

    assert_equal 1545.15, intervention.targets.first.product.activity_production.total_input_cost.to_f
    assert_equal 0.0, intervention.targets.first.product.activity_production.total_tool_cost.to_f
    assert_equal 0.0, intervention.targets.first.product.activity_production.total_doer_cost.to_f
  end
end
