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
# == Table: issues
#
#  created_at           :datetime         not null
#  creator_id           :integer
#  custom_fields        :jsonb
#  dead                 :boolean          default(FALSE)
#  description          :text
#  geolocation          :geometry({:srid=>4326, :type=>"st_point"})
#  gravity              :integer
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  name                 :string           not null
#  nature               :string           not null
#  observed_at          :datetime         not null
#  picture_content_type :string
#  picture_file_name    :string
#  picture_file_size    :integer
#  picture_updated_at   :datetime
#  priority             :integer
#  state                :string
#  target_id            :integer
#  target_type          :string
#  updated_at           :datetime         not null
#  updater_id           :integer
#
require 'test_helper'

class IssueTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'killing target' do
    plant = Plant.all.detect { |p| p.dead_first_at.nil? && p.dead_at.nil? }
    assert plant
    now = Time.utc(2016, 10, 25, 20, 20, 20)

    last_death_at = now + 1.year
    last_issue = Issue.create!(target: plant, nature: :issue, observed_at: last_death_at, dead: true)
    plant.reload
    assert_equal last_death_at, plant.dead_at, 'Dead_at of plant should be updated'
    assert_equal plant.dead_first_at, plant.dead_at, 'Dead_at should be equal to dead_first_at'

    first_death_at = now + 1.month
    first_issue = Issue.create!(target: plant, nature: :issue, observed_at: first_death_at, dead: true)
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

    first_issue.destroy
    plant.reload
    assert_equal last_death_at, plant.dead_at, 'Dead_at of plant should be restored to last death datetime'
    assert_equal plant.dead_first_at, plant.dead_at, 'Dead_at should be equal to dead_first_at'

    last_issue.destroy
    plant.reload
    assert plant.dead_at.nil?, 'Dead_at of plant should be nil when no death registered'
  end
end
