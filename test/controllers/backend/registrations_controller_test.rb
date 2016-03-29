# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'test_helper'

module Backend
  class RegistrationsControllerTest < ActionController::TestCase
    # test_restfully_all_actions

    setup do
      sign_in(users(:users_001))
    end

    test 'approves user' do
      unapproved_user = users(:users_003)
      unapproved_user.update_column(:signup_at, Time.now)

      assert !unapproved_user.active_for_authentication?

      patch :update,
        id: unapproved_user.id,
        user: { first_name: unapproved_user.first_name,
                last_name: unapproved_user.last_name,
                language: unapproved_user.language,
                role_id: unapproved_user.role.id,
                email: unapproved_user.email }


      unapproved_user.reload
      assert_nil unapproved_user.signup_at
      assert unapproved_user.active_for_authentication?
      assert_redirected_to backend_registrations_path
    end
  end
end
