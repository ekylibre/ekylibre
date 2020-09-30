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
# == Table: activities
#
#  codes                        :jsonb
#  created_at                   :datetime         not null
#  creator_id                   :integer
#  cultivation_variety          :string
#  custom_fields                :jsonb
#  description                  :text
#  family                       :string           not null
#  grading_net_mass_unit_name   :string
#  grading_sizes_indicator_name :string
#  grading_sizes_unit_name      :string
#  id                           :integer          not null, primary key
#  lock_version                 :integer          default(0), not null
#  measure_grading_items_count  :boolean          default(FALSE), not null
#  measure_grading_net_mass     :boolean          default(FALSE), not null
#  measure_grading_sizes        :boolean          default(FALSE), not null
#  name                         :string           not null
#  nature                       :string           not null
#  production_campaign          :string
#  production_cycle             :string           not null
#  production_nature_id         :integer
#  production_system_name       :string
#  size_indicator_name          :string
#  size_unit_name               :string
#  support_variety              :string
#  suspended                    :boolean          default(FALSE), not null
#  updated_at                   :datetime         not null
#  updater_id                   :integer
#  use_countings                :boolean          default(FALSE), not null
#  use_gradings                 :boolean          default(FALSE), not null
#  use_seasons                  :boolean          default(FALSE)
#  use_tactics                  :boolean          default(FALSE)
#  with_cultivation             :boolean          not null
#  with_supports                :boolean          not null
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
      (intervention1.costing.doers_cost + intervention2.costing.doers_cost).to_i,
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
end
