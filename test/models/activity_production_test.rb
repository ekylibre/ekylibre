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
# == Table: activity_productions
#
#  activity_id          :integer          not null
#  campaign_id          :integer
#  created_at           :datetime         not null
#  creator_id           :integer
#  cultivable_zone_id   :integer
#  custom_fields        :jsonb
#  custom_name          :string
#  headland_shape       :geometry({:srid=>4326, :type=>"geometry"})
#  id                   :integer          not null, primary key
#  irrigated            :boolean          default(FALSE), not null
#  lock_version         :integer          default(0), not null
#  nitrate_fixing       :boolean          default(FALSE), not null
#  planting_campaign_id :integer
#  rank_number          :integer          not null
#  season_id            :integer
#  size_indicator_name  :string           not null
#  size_unit_name       :string
#  size_value           :decimal(19, 4)   not null
#  started_on           :date
#  state                :string
#  stopped_on           :date
#  support_id           :integer          not null
#  support_nature       :string
#  support_shape        :geometry({:srid=>4326, :type=>"multi_polygon"})
#  tactic_id            :integer
#  updated_at           :datetime         not null
#  updater_id           :integer
#  usage                :string           not null
#
require 'test_helper'

class ActivityProductionTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'create' do
    activity = Activity.find_by(production_cycle: :annual, family: 'plant_farming')
    p = activity.productions.new(started_on: '2015-07-01', stopped_on: '2016-01-15', campaign: Campaign.of(2016), cultivable_zone: CultivableZone.first)
    assert p.save, p.errors.inspect
    p = activity.productions.new(started_on: '2015-07-01', stopped_on: '72016-01-15', campaign: Campaign.of(2016), cultivable_zone: CultivableZone.first)
    assert !p.save, p.errors.inspect
    p = activity.productions.new(started_on: '15-07-01', stopped_on: '2016-01-15', campaign: Campaign.of(2016), cultivable_zone: CultivableZone.first)
    assert p.save, p.errors.inspect
    p = activity.productions.new(started_on: '2017-07-01', stopped_on: '2016-01-15', campaign: Campaign.of(2016), cultivable_zone: CultivableZone.first)
    assert !p.save, p.errors.inspect
  end

  test 'harvest_yield returns a measure' do
    cultivable_zone = create(:cultivable_zone)
    activity_production = create(:activity_production, cultivable_zone: cultivable_zone)
    result = activity_production.harvest_yield(:grass, procedure_category: :harvesting,
                                                       size_indicator_name: :net_mass,
                                                       size_unit_name: :ton,
                                                       surface_unit_name: :hectare)
    assert_equal Measure, result.class
  end

  # assert_in_delta cause psql ST_Area([...]) ~= Charta::MultiPolygon.area
  test 'working zone area 8' do
    production = ActivityProduction.find(8).decorate
    assert_in_delta 21.56007722495018, production.working_zone_area.to_d, 0.0005
  end

  test 'working zone area 6' do
    production = ActivityProduction.find(6).decorate
    assert_in_delta 0.0, production.working_zone_area.to_d, 0.0005
  end

  test 'working zone area 9' do
    production = ActivityProduction.find(9).decorate
    assert_in_delta 33.454308011622075, production.working_zone_area.to_d, 0.0005
  end

  test 'working zone area 49' do
    production = ActivityProduction.find(49).decorate
    assert_in_delta 1.958770832919594, production.working_zone_area.to_d, 0.0005
  end

  test 'costs' do
    production = create(:corn_activity_production, started_on: DateTime.new(2018, 1, 1))
    intervention1 = create(:intervention, started_at: DateTime.new(2018, 1, 2), stopped_at: DateTime.new(2018, 1, 2) + 2.hours)
    target = create(
      :intervention_target,
      product: production.products.first,
      intervention: intervention1,
      imputation_ratio: 1
    )
    doer = create(
      :driver,
      product: Product.find(79),
      intervention: intervention1
    )
    input = create(
      :intervention_input,
      product: Matter.find(59),
      intervention: intervention1
    )
    intervention1.save
    intervention2 = create(:intervention, started_at: DateTime.new(2018, 1, 2), stopped_at: DateTime.new(2018, 1, 2) + 2.hours)
    target = create(
      :intervention_target,
      product: production.products.first,
      intervention: intervention2,
      imputation_ratio: 1
    )
    doer = create(
      :driver,
      product: Product.find(79),
      intervention: intervention2
    )
    input = create(
      :intervention_input,
      product: Matter.find(59),
      intervention: intervention2
    )
    intervention2.save
    assert_equal(
      (intervention1.costing.doers_cost + intervention2.costing.doers_cost),
      production.decorate.global_costs[:doers]
    )
    assert_equal(
      (intervention1.costing.inputs_cost + intervention2.costing.inputs_cost),
      production.decorate.global_costs[:inputs]
    )
  end

  test 'costs intervention on multiple productions' do
    production1 = create(:corn_activity_production, started_on: DateTime.new(2018, 1, 1))
    production2 = create(:lemon_activity_production, started_on: DateTime.new(2018, 1, 1))
    intervention = create(:intervention, started_at: DateTime.new(2018, 1, 2), stopped_at: DateTime.new(2018, 1, 2) + 2.hours)
    ratio1 = (production1.support_shape_area / (
        production1.support_shape_area + production2.support_shape_area
      )).to_f
    target1 = create(
      :intervention_target,
      product: production1.products.first,
      intervention: intervention,
      imputation_ratio: ratio1
    )
    ratio2 = (production2.support_shape_area / (
        production1.support_shape_area + production2.support_shape_area
      )).to_f
    target2 = create(
      :intervention_target,
      product: production2.products.first,
      intervention: intervention,
      imputation_ratio: ratio2
    )
    doer = create(
      :driver,
      product: Product.find(79),
      intervention: intervention
    )
    input = create(
      :intervention_input,
      product: Matter.find(59),
      intervention: intervention
    )
    intervention.save
    assert_equal(
      (intervention.costing.doers_cost * ratio1).to_i,
      production1.decorate.global_costs[:doers]
    )
    assert_equal(
      (intervention.costing.inputs_cost * ratio1).to_i,
      production1.decorate.global_costs[:inputs]
    )
    assert_equal(
      (intervention.costing.doers_cost * ratio2).to_i,
      production2.decorate.global_costs[:doers]
    )
    assert_equal(
      (intervention.costing.inputs_cost * ratio2).to_i,
      production2.decorate.global_costs[:inputs]
    )
  end
end
