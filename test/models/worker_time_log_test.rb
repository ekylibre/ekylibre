# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: worker_time_logs
#
#  created_at    :datetime         not null
#  creator_id    :integer(4)
#  custom_fields :jsonb            default("{}")
#  description   :text
#  duration      :integer(4)       not null
#  id            :integer(4)       not null, primary key
#  lock_version  :integer(4)       default(0), not null
#  provider      :jsonb            default("{}")
#  started_at    :datetime         not null
#  stopped_at    :datetime         not null
#  updated_at    :datetime         not null
#  updater_id    :integer(4)
#  worker_id     :integer(4)       not null
#
require 'test_helper'

class WorkerTimeLogTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  # setup entity with worker and contract
  setup do
    I18n.locale = :fra
    @entity = create(:entity, :worker)
    @worker_contract = WorkerContract.import_from_lexicon(reference_name: 'permanent_salaried', entity_id: @entity.id)
    @worker = Worker.find_by(person_id: @entity.id)
  end

  test 'should compute duration from started_at and stopped_at' do
    time_log = @worker.time_logs.create!(started_at: (Time.zone.now - 1.hours), stopped_at: Time.zone.now)
    assert_equal 3600, time_log.duration
  end

  test 'should compute stopped_at from started_at and duration' do
    time_log = @worker.time_logs.create!(started_at: (Time.zone.now - 1.hours), duration: 3600)
    assert_equal (time_log.started_at + time_log.duration), time_log.stopped_at
  end

end
