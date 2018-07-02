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
# == Table: activity_productions
#
#  activity_id            :integer          not null
#  batch_planting         :boolean
#  campaign_id            :integer
#  created_at             :datetime         not null
#  creator_id             :integer
#  cultivable_zone_id     :integer
#  custom_fields          :jsonb
#  id                     :integer          not null, primary key
#  irrigated              :boolean          default(FALSE), not null
#  lock_version           :integer          default(0), not null
#  nitrate_fixing         :boolean          default(FALSE), not null
#  number_of_batch        :integer
#  predicated_sowing_date :date
#  rank_number            :integer          not null
#  season_id              :integer
#  size_indicator_name    :string           not null
#  size_unit_name         :string
#  size_value             :decimal(19, 4)   not null
#  sowing_interval        :integer
#  started_on             :date
#  state                  :string
#  stopped_on             :date
#  support_id             :integer          not null
#  support_nature         :string
#  support_shape          :geometry({:srid=>4326, :type=>"multi_polygon"})
#  tactic_id              :integer
#  updated_at             :datetime         not null
#  updater_id             :integer
#  usage                  :string           not null
#
require 'test_helper'

class ActivityProductionTest < ActiveSupport::TestCase
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
end
