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
# == Table: activities
#
#  codes                          :jsonb
#  created_at                     :datetime         not null
#  creator_id                     :integer
#  cultivation_variety            :string
#  custom_fields                  :jsonb
#  description                    :text
#  family                         :string           not null
#  grading_net_mass_unit_name     :string
#  grading_sizes_indicator_name   :string
#  grading_sizes_unit_name        :string
#  id                             :integer          not null, primary key
#  life_duration                  :decimal(5, 2)
#  lock_version                   :integer          default(0), not null
#  measure_grading_items_count    :boolean          default(FALSE), not null
#  measure_grading_net_mass       :boolean          default(FALSE), not null
#  measure_grading_sizes          :boolean          default(FALSE), not null
#  name                           :string           not null
#  nature                         :string           not null
#  production_cycle               :string           not null
#  production_nature_id           :integer
#  production_started_on          :date
#  production_started_on_year     :integer
#  production_stopped_on          :date
#  production_stopped_on_year     :integer
#  production_system_name         :string
#  size_indicator_name            :string
#  size_unit_name                 :string
#  start_state_of_production_year :integer
#  support_variety                :string
#  suspended                      :boolean          default(FALSE), not null
#  updated_at                     :datetime         not null
#  updater_id                     :integer
#  use_countings                  :boolean          default(FALSE), not null
#  use_gradings                   :boolean          default(FALSE), not null
#  use_seasons                    :boolean          default(FALSE)
#  use_tactics                    :boolean          default(FALSE)
#  with_cultivation               :boolean          not null
#  with_supports                  :boolean          not null
#
require 'test_helper'

class ActivityTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'costs' do
    production = create(:corn_activity_production, started_on: DateTime.new(2018, 1, 1))
    activity = production.activity
    intervention1 = create(:intervention, started_at: DateTime.new(2018, 1, 2), stopped_at: DateTime.new(2018, 1, 2) + 2.hours)
    target = create(
      :intervention_target,
      product: production.products.first,
      intervention: intervention1
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
      intervention: intervention2
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
      activity.decorate.production_costs(production.campaign)[:global_costs][:doers]
    )
    assert_equal(
      (intervention1.costing.inputs_cost + intervention2.costing.inputs_cost),
      activity.decorate.production_costs(production.campaign)[:global_costs][:inputs]
    )
  end

  test 'costs intervention on multiple productions' do
    production1 = create(
      :corn_activity_production,
      started_on: DateTime.new(2018, 1, 1)
    )
    activity = production1.activity
    production2 = create(
      :corn_activity_production,
      activity: activity,
      started_on: DateTime.new(2018, 1, 1),
      campaign: production1.campaign
    )
    intervention = create(:intervention, started_at: DateTime.new(2018, 1, 2), stopped_at: DateTime.new(2018, 1, 2) + 2.hours)
    target1 = create(
      :intervention_target,
      product: production1.products.first,
      intervention: intervention,
      working_zone: production1.support_shape.to_rgeo
    )
    target2 = create(
      :intervention_target,
      product: production2.products.first,
      intervention: intervention,
      working_zone: production2.support_shape.to_rgeo
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
      intervention.costing.doers_cost,
      activity.decorate.production_costs(production1.campaign)[:global_costs][:doers]
    )
    assert_equal(
      intervention.costing.inputs_cost,
      activity.decorate.production_costs(production1.campaign)[:global_costs][:inputs]
    )
  end

  # assert_in_delta cause psql ST_Area([...]) ~= Charta::MultiPolygon.area
  test 'working zone area 1' do
    activity = Activity.find(1).decorate
    assert_in_delta 55.01438523657225, activity.working_zone_area(Campaign.find(4)).to_d, 0.0005
  end

  test 'working zone area 6' do
    activity = Activity.find(6).decorate
    assert_in_delta 0.0, activity.working_zone_area(Campaign.find(4)).to_d, 0.0005
  end

  test 'net surface area 1' do
    activity = Activity.find(1).decorate
    assert_in_delta 18.475156708706745, activity.net_surface_area(Campaign.find(4)).to_d, 0.0005
  end

  test 'net surface area 5' do
    activity = Activity.find(5).decorate
    assert_in_delta 4.005935795594734, activity.net_surface_area(Campaign.find(4)).to_d, 0.0005
  end

  test 'net surface area 6' do
    activity = Activity.find(6).decorate
    assert_in_delta 5.404837559111416, activity.net_surface_area(Campaign.find(4)).to_d, 0.0005
  end

  test 'net surface area 7' do
    activity = Activity.find(7).decorate
    assert_in_delta 0.0, activity.net_surface_area(Campaign.find(4)).to_d, 0.0005
  end

  test "can't edit activity family if there is any production associated" do
    activity = create(:activity, :perennial, family: :plant_farming)
    assert_nothing_raised do
      activity.update!(family: :animal_farming, cultivation_variety: :animal)
    end

    activity = create(:activity, :with_productions, :perennial, family: :plant_farming)
    assert_raises ActiveRecord::RecordInvalid do
      activity.update!(family: :animal_farming, cultivation_variety: :animal)
    end
  end

  test "can't edit activity family if the cultivation_variety is not one of its children" do
    activity = create(:activity, :perennial, family: :plant_farming, cultivation_variety: :plant)
    assert_raises ActiveRecord::RecordInvalid do
      activity.update!(family: :animal_farming)
    end

    assert_nothing_raised do
      activity.update!(family: :animal_farming, cultivation_variety: :animal)
    end
  end

  test 'left_join_working_duration_of_campaign on multiple targets' do
    campaign = Campaign.find_by(harvest_year: 2017)
    production1 = create(
      :corn_activity_production,
      started_on: DateTime.new(2017, 1, 1),
      campaign: campaign
    )
    production2 = create(
      :lemon_activity_production,
      started_on: DateTime.new(2017, 1, 1),
      campaign: campaign
    )
    intervention = create(:intervention, started_at: DateTime.new(2017, 1, 2), stopped_at: DateTime.new(2017, 1, 2) + 2.hours)
    target1 = create(
      :intervention_target,
      product: production1.products.first,
      intervention: intervention,
      working_zone: production1.support_shape.to_rgeo
    )
    target2 = create(
      :intervention_target,
      product: production2.products.first,
      intervention: intervention,
      working_zone: production2.support_shape.to_rgeo
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
    intervention.save!
    target1.reload
    target2.reload

    activities = Activity.left_join_working_duration_of_campaign(production1.campaign).where(id: [production1.activity_id, production2.activity_id])
    assert_equal intervention.working_duration * target1.imputation_ratio, activities.find { |activity| activity.id == production1.activity_id }.working_duration
    assert_equal intervention.working_duration * target2.imputation_ratio, activities.find { |activity| activity.id == production2.activity_id }.working_duration
  end

  class AnimalFarmingActivityTest < ActivityTest
    setup do
      @activity = Activity.create(attributes_for(:activity, family: 'animal_farming'))
    end

    test 'create new activity with defaults attributes' do
      attributes = {
        with_supports: true,
        support_variety: 'animal_group',
        with_cultivation: true,
        cultivation_variety: 'animal',
        size_indicator_name: 'members_population',
        size_unit_name: 'unity',
        production_cycle: 'perennial',
        life_duration: 20
      }
      assert_attributes_equals(attributes, @activity)
    end
  end

  class PlantFarmingActivityTest < ActivityTest
    setup do
      @activity = Activity.create(attributes_for(:activity, family: 'plant_farming'))
    end

    test 'create new activity with defaults attributes' do
      attributes = {
        with_supports: true,
        support_variety: 'land_parcel',
        with_cultivation: true,
        cultivation_variety: 'plant',
        size_indicator_name: 'net_surface_area',
        size_unit_name: 'hectare',
      }
      assert_attributes_equals(attributes, @activity)
    end
  end

  class ToolMaintainingActivityTest < ActivityTest
    setup do
      @activity = Activity.create(attributes_for(:activity, family: 'tool_maintaining'))
    end

    test 'create new activity with defaults attributes' do
      attributes = {
        with_supports: true,
        support_variety: 'equipment_fleet',
        with_cultivation: true,
        cultivation_variety: 'equipment',
        size_indicator_name: 'members_population',
        size_unit_name: 'unity',
      }
      assert_attributes_equals(attributes, @activity)
    end
  end

  class VineFarmingActivityTest < ActivityTest
    setup do
      @activity = Activity.create(attributes_for(:activity, family: 'vine_farming'))
    end

    test 'create new activity with defaults attributes' do
      attributes = {
        with_supports: true,
        support_variety: 'land_parcel',
        with_cultivation: true,
        size_indicator_name: 'net_surface_area',
        size_unit_name: 'hectare',
        reference_name: 'vine',
        cultivation_variety: 'vitis',
        production_cycle: 'perennial',
        start_state_of_production_year: 3,
        life_duration: 50.00,
      }
      assert_attributes_equals(attributes, @activity)
    end
  end

  private
    def assert_attributes_equals(expected_attributes, activity)
      expected_attributes.each do |attribute, value|
        assert_equal( value, activity.send(attribute))
      end
    end
end
