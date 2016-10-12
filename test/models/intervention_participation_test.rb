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
# == Table: intervention_participations
#
#  created_at        :datetime         not null
#  creator_id        :integer
#  id                :integer          not null, primary key
#  intervention_id   :integer
#  lock_version      :integer          default(0), not null
#  nature            :string
#  product_id        :integer
#  request_compliant :boolean          default(FALSE), not null
#  started_at        :datetime
#  stopped_at        :datetime
#  updated_at        :datetime         not null
#  updater_id        :integer
#
require 'test_helper'

class InterventionParticipationTest < ActiveSupport::TestCase
  test_model_actions

  setup do
    @intervention = Intervention.create!(procedure_name: :sowing, actions: [:sowing])
    @worker = Worker.create!(name: 'Alice', variety: 'worker', variant: ProductNatureVariant.first, person: Entity.contacts.first)

    @participation = @worker.intervention_participations.create!(intervention_id: @intervention.id, state: :in_progress)
  end

  test 'only one participation per worker per intervention' do
    assert_raises { @worker.intervention_participations.create!(intervention_id: @intervention.id, state: :in_progress) }
  end

  test 'setting an intervention\'s state to done sets all participations\' states to done' do
    @intervention.update!(state: :done)
    @participation.reload

    assert_equal :done, @participation.state.to_sym
  end

  test 'creating an :in_progress participation sets the intervention\'s to :in_progress' do
    done_int = Intervention.create!(procedure_name: :sowing, actions: [:sowing], state: :done)
    @worker.intervention_participations.create!(intervention_id: done_int.id, state: :in_progress)
    done_int.reload

    assert_equal :in_progress, done_int.state.to_sym
  end

  test 'working periods in a participation shouldn\'t be able to overlap' do
    @participation.working_periods.create!(nature: :travel, started_at: Time.zone.now, stopped_at: Time.zone.now + 1.hour)
    assert_raises { @participation.working_periods.create!(nature: :intervention, started_at: Time.zone.now - 30.minutes, stopped_at: Time.zone.now + 30.minutes) }
  end
end
