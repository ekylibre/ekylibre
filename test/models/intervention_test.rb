# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
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
#  created_at       :datetime         not null
#  creator_id       :integer
#  description      :text
#  event_id         :integer
#  id               :integer          not null, primary key
#  issue_id         :integer
#  lock_version     :integer          default(0), not null
#  number           :string
#  prescription_id  :integer
#  procedure_name   :string           not null
#  started_at       :datetime
#  state            :string           not null
#  stopped_at       :datetime
#  updated_at       :datetime         not null
#  updater_id       :integer
#  whole_duration   :integer
#  working_duration :integer
#
require 'test_helper'

class InterventionTest < ActiveSupport::TestCase
  test 'scopes' do
    cast = InterventionCast.first # intervention_casts(:intervention_casts_001)
    actor = cast.product
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

  test 'protect on destroy' do
    # It should not be possible to destroy an intervention marked as done
    assert_raise Ekylibre::Record::RecordNotDestroyable do
      Intervention.destroy(interventions(:interventions_001).id)
    end
  end

  test 'intervention creation' do
    intervention = Intervention.create!(procedure_name: :sowing) # , actions: [:game_repellent, :fungicide]
    Worker.of_expression('can drive(equipment) and can move').limit(2) do |bob|
      intervention.add!(:driver, bob)
    end
    intervention.add!(:tractor, Equipment.of_expression('can tow(equipment) and can move').first)
    intervention.add!(:sower, Equipment.of_expression('can sow').first)
    intervention.add!(:seeds, Product.of_expression('is seed and derives from plant and can grow').first, quantity: 25.in_kilogram, quantity_handler: :net_mass)
    cultivation_variant = ProductNatureVariant.import_from_nomenclature(:wheat_crop)
    LandParcel.of_expression('can store(plant)').limit(3).each do |land_parcel|
      intervention.add!(:zone) do |g|
        g.add!(:land_parcel, land_parcel)
        g.add!(:cultivation, variant: cultivation_variant, working_zone: land_parcel.shape)
      end
    end
    assert intervention.runnable?, 'Intervention should be runnable'
  end
end
