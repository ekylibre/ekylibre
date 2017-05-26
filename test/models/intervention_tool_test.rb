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
#  type                     :string
#  unit_pretax_stock_amount :decimal(19, 4)   default(0.0), not null
#  updated_at               :datetime         not null
#  updater_id               :integer
#  variant_id               :integer
#  working_zone             :geometry({:srid=>4326, :type=>"multi_polygon"})
#
require 'test_helper'

class InterventionToolTest < ActiveSupport::TestCase
  test_model_actions

  setup do
    @worker = Worker.create!(
      name: 'Alice',
      variety: 'worker',
      variant: ProductNatureVariant.first,
      person: Entity.contacts.first
    )

    @tractor = Product.create!(
      name: 'John Deere',
      variety: 'tractor',
      variant: ProductNatureVariant.where(variety: :tractor).first
    )

    @intervention = Intervention.create!(
      procedure_name: :sowing,
      actions: [:sowing],
      request_compliant: false,
      working_periods: fake_working_periods
    )

    @intervention.reload
  end

  test 'working duration without participation' do
    add_intervention_doer
    add_intervention_tool

    intervention_tool = @intervention.tools.first

    assert_equal intervention_tool.working_duration, @intervention.working_duration
  end

  test 'working duration' do
    add_intervention_doer
    add_intervention_tool

    intervention_tool = @intervention.tools.first

    now = Time.zone.now

    InterventionParticipation.create!(
      intervention: @intervention,
      state: :done,
      request_compliant: false,
      procedure_name: :sowing,
      product: @worker,
      working_periods_attributes: [
        {
          started_at: now - 1.hour,
          stopped_at: now - 30.minutes,
          nature: 'travel'
        },
        {
          started_at: now - 1.hour,
          stopped_at: now - 50.minutes,
          nature: 'preparation'
        },
        {
          started_at: now - 30.minutes,
          stopped_at: now - 15.minutes,
          nature: 'intervention'
        },
        {
          started_at: now - 10.minutes,
          stopped_at: now,
          nature: 'intervention'
        }
      ]
    )

    @intervention.reload

    assert_equal intervention_tool.working_duration, 35.minutes.to_i / 1
    assert_equal intervention_tool.working_duration(nature: :intervention), 25.minutes.to_i / 1
    assert_equal intervention_tool.working_duration(nature: :preparation), 10.minutes.to_i / 1
  end

  def add_intervention_doer
    @intervention.doers.create!(
      product: @worker,
      reference_name: 'land_parcel'
    )
  end

  def add_intervention_tool
    @intervention.tools.create!(
      product: @tractor,
      reference_name: 'tractor'
    )
  end

  def fake_working_periods
    now = Time.zone.now
    [
      InterventionWorkingPeriod.new(started_at: now - 3.hours, stopped_at: now - 2.hours, nature: 'preparation'),
      InterventionWorkingPeriod.new(started_at: now - 2.hours, stopped_at: now - 90.minutes, nature: 'travel'),
      InterventionWorkingPeriod.new(started_at: now - 90.minutes, stopped_at: now - 30.minutes, nature: 'intervention'),
      InterventionWorkingPeriod.new(started_at: now - 30.minutes, stopped_at: now, nature: 'travel')
    ]
  end
end
