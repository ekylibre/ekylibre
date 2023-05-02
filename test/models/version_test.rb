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
# == Table: versions
#
#  created_at   :datetime         not null
#  creator_id   :integer(4)
#  creator_name :string
#  event        :string           not null
#  id           :integer(4)       not null, primary key
#  item_changes :text
#  item_id      :integer(4)
#  item_object  :text
#  item_type    :string
#
require 'test_helper'

class VersionTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'version of entity last name' do
    e = Entity.create! first_name: 'Charly', last_name: 'Watts'
    e.update! first_name: 'Mick', last_name: 'Jagger'
    e.reload
    assert e.valid?
    change = e.versions.first.changes.last
    assert_equal e.human_changed_attribute_value(change, 'old'), 'Watts'
    assert_equal e.human_changed_attribute_value(change, 'new'), 'Jagger'
  end

end
