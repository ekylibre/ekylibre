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
# == Table: roles
#
#  created_at     :datetime         not null
#  creator_id     :integer
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  name           :string           not null
#  reference_name :string
#  rights         :text
#  updated_at     :datetime         not null
#  updater_id     :integer
#

require 'test_helper'

class RoleTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  test 'rights changes echo' do
    manager = Role.create!(name: 'Manager')

    bob = User.create!(
      first_name: 'Bob',
      last_name: 'Doe',
      language: :jpn,
      email: 'bob@doe.foo',
      password: '123456789',
      password_confirmation: '123456789',
      role: manager
    )

    manager.rights = {
      'sales' => %w[read write]
    }
    manager.save!

    bob.reload
    assert bob.rights['sales'], 'User should have right resource "sales"'
    assert bob.rights['sales'].include?('read'), 'User should have right "read-sales"'
    assert bob.rights['sales'].include?('write'), 'User should have right "write-sales"'
  end
end
