# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  accounted_at            :datetime
#  actions                 :string
#  created_at              :datetime         not null
#  creator_id              :integer
#  currency                :string
#  custom_fields           :jsonb
#  description             :text
#  event_id                :integer
#  id                      :integer          not null, primary key
#  issue_id                :integer
#  journal_entry_id        :integer
#  lock_version            :integer          default(0), not null
#  nature                  :string           not null
#  number                  :string
#  prescription_id         :integer
#  procedure_name          :string           not null
#  request_intervention_id :integer
#  started_at              :datetime
#  state                   :string           not null
#  stopped_at              :datetime
#  trouble_description     :text
#  trouble_encountered     :boolean          default(FALSE), not null
#  updated_at              :datetime         not null
#  updater_id              :integer
#  whole_duration          :integer          default(0), not null
#  working_duration        :integer          default(0), not null
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
    intervention = Intervention.create!(procedure_name: :sowing) # , actions: [:game_repellent, :fungicide]
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

  test 'run!' do
    intervention = Intervention.run!(:sowing) do |i|
      Worker.of_expression('can drive(equipment) and can move').limit(2) do |bob|
        i.add!(:driver, bob)
      end
      i.add!(:tractor, Equipment.of_expression('can tow(equipment) and can move').first)
      i.add!(:sower, Equipment.of_expression('can sow').first)
      i.add!(:seeds, Product.of_expression('is seed and derives from plant and can grow').first, quantity_population: 5) # , quantity: 25.in_kilogram, quantity_handler: :net_mass)
      cultivation_variant = ProductNatureVariant.import_from_nomenclature(:wheat_crop)
      LandParcel.of_expression('can store(plant)').limit(3).each do |land_parcel|
        i.add!(:zone) do |g|
          g.add!(:land_parcel, land_parcel)
          g.add!(:plant, variant: cultivation_variant, working_zone: land_parcel.shape, quantity_population: land_parcel.shape_area / cultivation_variant.net_surface_area)
        end
      end
    end
  end

  test 'invalid cases' do
    intervention = Intervention.new(procedure_name: :sowing, actions: [:sowing])
    assert intervention.save, 'Intervention with invalid actions should be saved'
    intervention = Intervention.new(procedure_name: :sowing, actions: [:loosening])
    assert_not intervention.save, 'Intervention with invalid actions should not be saved'
    intervention = Intervention.new(procedure_name: :sowing, actions: [:sowing, :loosening])
    assert_not intervention.save, 'Intervention with invalid actions should not be saved'
  end

  test 'destroy intervention update intervention_activities_db_view' do
    first_activity_intervention = Intervention::HABTM_Activities.first
    assert Intervention.destroy(first_activity_intervention.intervention_id)
  end
end
