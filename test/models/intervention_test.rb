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
# == Table: interventions
#
#  accounted_at                   :datetime
#  actions                        :string
#  auto_calculate_working_periods :boolean          default(FALSE)
#  created_at                     :datetime         not null
#  creator_id                     :integer
#  currency                       :string
#  custom_fields                  :jsonb
#  description                    :text
#  event_id                       :integer
#  id                             :integer          not null, primary key
#  intervention_costs_id          :integer
#  issue_id                       :integer
#  journal_entry_id               :integer
#  lock_version                   :integer          default(0), not null
#  nature                         :string           not null
#  number                         :string
#  prescription_id                :integer
#  procedure_name                 :string           not null
#  purchase_id                    :integer
#  request_compliant              :boolean
#  request_intervention_id        :integer
#  started_at                     :datetime         not null
#  state                          :string           not null
#  stopped_at                     :datetime         not null
#  trouble_description            :text
#  trouble_encountered            :boolean          default(FALSE), not null
#  updated_at                     :datetime         not null
#  updater_id                     :integer
#  whole_duration                 :integer          not null
#  working_duration               :integer          not null
#
require 'test_helper'

class InterventionTest < ActiveSupport::TestCase
  test_model_actions

  test 'scopes' do
    parameter = InterventionProductParameter.first # intervention_parameters(:intervention_parameters_001)
    actor = parameter.product
    assert actor, 'Actor can not be nil for following assertions'
    assert_nothing_raised do
      Intervention.with_generic_cast(:tool, actor)
    end
    assert_nothing_raised do
      Intervention.with_generic_cast('tool', actor)
    end
    assert_raise ArgumentError do
      Intervention.with_generic_cast(:unknown_role, actor)
    end
    assert_raise ArgumentError do
      Intervention.with_generic_cast('grinding-tool', actor)
    end
    assert_raise ArgumentError do
      Intervention.with_generic_cast(:'grinding-tool', actor)
    end
  end

  test 'destruction protection' do
    # It should not be possible to destroy an intervention marked as done
    assert_not interventions(:interventions_005).destroyable?
    assert_raise Ekylibre::Record::RecordNotDestroyable do
      Intervention.destroy(interventions(:interventions_005).id)
    end
  end

  test 'creation and destruction' do
    intervention = Intervention.create!(
      procedure_name: :sowing,
      working_periods: fake_working_periods,
      # , actions: [:game_repellent, :fungicide]
    )
    Worker.of_expression('can drive(equipment) and can move').limit(2) do |bob|
      intervention.add_parameter!(:driver, bob)
    end
    intervention.add_parameter!(:tractor, Equipment.of_expression('can tow(equipment) and can move').first)
    intervention.add_parameter!(:sower, Equipment.of_expression('can sow').first)
    intervention.add_parameter!(:seeds, Product.of_expression('is seed and derives from plant and can grow').first, quantity: 25.in_kilogram, quantity_handler: :net_mass, quantity_population: 1)
    cultivation_variant = ProductNatureVariant.import_from_nomenclature(:wheat_crop)
    LandParcel.of_expression('can store(plant)').limit(3).each do |land_parcel|
      intervention.add_parameter!(:zone) do |g|
        g.add_parameter!(:land_parcel, land_parcel)
        g.add_parameter!(:plant, variant: cultivation_variant, working_zone: land_parcel.shape, quantity_population: land_parcel.shape_area / cultivation_variant.net_surface_area)
      end
    end
    assert intervention.runnable?, 'Intervention should be runnable'

    intervention.destroy!
  end

  test 'invalid cases' do
    intervention = Intervention.new(procedure_name: :sowing, actions: [:sowing], working_periods: fake_working_periods)
    assert intervention.save, 'Intervention with invalid actions should be saved: ' + intervention.errors.full_messages.to_sentence(locale: :eng)
    intervention = Intervention.new(procedure_name: :sowing, actions: [:loosening], working_periods: fake_working_periods)
    refute intervention.save, 'Intervention with invalid actions should not be saved: ' + intervention.errors.full_messages.to_sentence(locale: :eng)
    intervention = Intervention.new(procedure_name: :sowing, actions: %i[sowing loosening], working_periods: fake_working_periods)
    refute intervention.save, 'Intervention with invalid actions should not be saved: ' + intervention.errors.full_messages.to_sentence(locale: :eng)
  end

  test 'killing target' do
    plant = Plant.all.detect { |p| p.dead_first_at.nil? && p.dead_at.nil? }
    assert plant
    now = Time.utc(2016, 10, 25, 20, 20, 20)

    last_death_at = now + 1.year
    last_intervention = add_harvesting_intervention(plant, last_death_at)
    plant.reload
    assert_equal last_death_at, plant.dead_at, 'Dead_at of plant should be updated'
    assert_equal plant.dead_first_at, plant.dead_at, 'Dead_at should be equal to dead_first_at'

    first_death_at = now + 1.month
    first_intervention = add_harvesting_intervention(plant, first_death_at)
    plant.reload
    assert_equal first_death_at, plant.dead_at, 'Dead_at of plant should be updated'
    assert_equal plant.dead_first_at, plant.dead_at, 'Dead_at should be equal to dead_first_at'

    middle_death_at = now + 6.months
    middle_issue = Issue.create!(target: plant, nature: :issue, observed_at: middle_death_at, dead: true)
    plant.reload
    assert_equal first_death_at, plant.dead_at, 'Dead_at of plant should not be updated'
    assert_equal plant.dead_first_at, plant.dead_at, 'Dead_at should be equal to dead_first_at'

    middle_issue.destroy
    plant.reload
    assert_equal first_death_at, plant.dead_at, 'Dead_at of plant should not be restored to middle death datetime'
    assert_equal plant.dead_first_at, plant.dead_at, 'Dead_at should be equal to dead_first_at'

    first_intervention.destroy
    plant.reload
    assert_equal last_death_at, plant.dead_at, 'Dead_at of plant should be restored to last death datetime'
    assert_equal plant.dead_first_at, plant.dead_at, 'Dead_at should be equal to dead_first_at'

    last_intervention.destroy
    plant.reload
    assert plant.dead_at.nil?, 'Dead_at of plant should be nil when no death registered'
  end

  test 'cost_per_area' do
    cultivable_zone = create(:cultivable_zone)
    activity_production = create(:activity_production, cultivable_zone: cultivable_zone)
    intervention = create(:intervention)
    create(:intervention_target, intervention: intervention, product: activity_production.support, working_zone: activity_production.support.initial_shape)
    assert_equal 0.0, intervention.cost_per_area(:target)
  end

  def add_harvesting_intervention(target, stopped_at)
    Intervention.create!(
      procedure_name: :harvesting,
      working_periods_attributes: {
        '0' => {
          started_at: stopped_at - 4.hours,
          stopped_at: stopped_at,
          nature: 'intervention'
        }
      },
      targets_attributes: {
        '0' => {
          reference_name: :plant,
          product_id: target.id,
          dead: true
        }
      }
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
