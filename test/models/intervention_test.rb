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
# == Table: interventions
#
#  accounted_at                   :datetime
#  actions                        :string
#  auto_calculate_working_periods :boolean          default(FALSE)
#  costing_id                     :integer
#  created_at                     :datetime         not null
#  creator_id                     :integer
#  currency                       :string
#  custom_fields                  :jsonb
#  description                    :text
#  event_id                       :integer
#  id                             :integer          not null, primary key
#  issue_id                       :integer
#  journal_entry_id               :integer
#  lock_version                   :integer          default(0), not null
#  nature                         :string           not null
#  number                         :string
#  parent_id                      :integer
#  prescription_id                :integer
#  procedure_name                 :string           not null
#  provider                       :jsonb
#  providers                      :jsonb
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
#  validator_id                   :integer
#  whole_duration                 :integer          not null
#  working_duration               :integer          not null
#
require 'test_helper'

class InterventionTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
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

    # This was updated from Ekylibre::Record::RecordNotDestroyable to ActiveRecord::DeleteRestrictionError because it seems the last changes
    # made the ActiveRecord callbacks checking for dependent models run BEFORE the Ekylibre::Record::Acts::Protected callbacks.
    assert_raise ActiveRecord::DeleteRestrictionError do
      Intervention.destroy(interventions(:interventions_005).id)
    end
  end

  test 'creation and destruction' do
    intervention = create(:sowing_intervention_with_all_parameters)
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
    # plant born_at 2013-11-10
    assert plant
    now = plant.born_at
    last_death_at = now + 3.months
    last_intervention = add_harvesting_intervention(plant, last_death_at)
    plant.reload
    assert_equal last_death_at, plant.dead_at, 'Dead_at of plant should be updated'
    assert_equal plant.dead_first_at, plant.dead_at, 'Dead_at should be equal to dead_first_at'

    first_death_at = now + 1.month
    first_intervention = add_harvesting_intervention(plant, first_death_at)
    plant.reload
    assert_equal first_death_at, plant.dead_at, 'Dead_at of plant should be updated'
    assert_equal plant.dead_first_at, plant.dead_at, 'Dead_at should be equal to dead_first_at'

    middle_death_at = now + 2.months
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
    land_parcel = create(:land_parcel)
    intervention = create(:intervention, :with_target, on: land_parcel, reference_name: 'land_parcel')

    intervention.reload
    assert_equal 0.0, intervention.cost_per_area(:target)
  end

  test 'update variant of sowing intervention should create new product and destroy old one if the product is not used elsewhere' do
    intervention = create(:sowing_intervention_with_all_parameters)
    intervention.reload
    output = intervention.outputs.last
    product = output.product
    new_variant = create(:corn_plant_variant)
    output.update(variant_id: new_variant.id)
    assert_nil Product.find_by(id: product.id)
    assert output.product
  end

  test 'update variant of sowing intervention should return error if the product is used elsewhere' do
    intervention = create(:sowing_intervention_with_all_parameters)
    intervention.reload
    output = intervention.outputs.last
    product = output.product
    packaging_intervention = create(:intervention, :packaging)
    packaging_input = create(:intervention_input, product: product, intervention: packaging_intervention, reference_name: :product_to_prepare)
    new_variant = create(:corn_plant_variant)
    output.update(variant_id: new_variant.id)
    assert !output.valid?
  end

  test "can't create or edit an intervention if any of the working periods is during a period of an opened financial year exchange AND there is inputs or outputs AND permanent stock inventory is activated" do
    Preference.set!(:permanent_stock_inventory, true)
    FinancialYear.delete_all
    fy = create(:financial_year, year: 2021)
    create(:financial_year_exchange, :opened, financial_year: fy, started_on: '2021-01-01', stopped_on: '2021-02-01')
    int = build(:intervention, :spraying, started_at: '2021-01-15 15:00', stopped_at: '2021-01-15 16:00')
    assert_not int.valid?

    Preference.set!(:permanent_stock_inventory, false)
    assert int.valid?
  end

  test "#handle_targets_imputation_ratio calculate the right ratio with cultivation targets" do
    # on create with 2 targets
    intervention = build(:intervention)
    targets = build_list(:intervention_target, 2, :with_cultivation, reference_name: 'land_parcel')
    intervention.targets << targets
    intervention.save
    target = targets.first.reload
    assert_equal(0.5, target.imputation_ratio)

    # on update, when adding a new target
    other_targets = build(:intervention_target, :with_cultivation, reference_name: 'land_parcel')
    intervention.targets << other_targets
    intervention.save
    target = intervention.reload.targets.first.reload
    assert_equal(0.3333, target.imputation_ratio)
  end

  test "#handle_targets_imputation_ratio calculate the right ratio with animal targets" do
    intervention = build(:intervention, procedure_name: 'animal_artificial_insemination', actions: [:animal_artificial_insemination])
    animal = create(:animal, born_at: DateTime.new(2017, 3, 1))
    targets = build_list(:intervention_target, 2, product_id: animal.id, reference_name: 'animal')
    intervention.targets << targets
    intervention.save
    target = targets.first.reload
    assert_equal(0.5, target.imputation_ratio)
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
    now = Time.zone.parse('2018-1-1 00:00:00')
    [
      InterventionWorkingPeriod.new(started_at: now - 3.hours, stopped_at: now - 2.hours, nature: 'preparation'),
      InterventionWorkingPeriod.new(started_at: now - 2.hours, stopped_at: now - 90.minutes, nature: 'travel'),
      InterventionWorkingPeriod.new(started_at: now - 90.minutes, stopped_at: now - 30.minutes, nature: 'intervention'),
      InterventionWorkingPeriod.new(started_at: now - 30.minutes, stopped_at: now, nature: 'travel')
    ]
  end
end
