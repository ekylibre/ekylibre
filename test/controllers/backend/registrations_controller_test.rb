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
    include ActiveJob::TestHelper

    # test_restfully_all_actions

    def set_unapproved_user
      unapproved_user = users(:users_003)
      unapproved_user.update_column(:signup_at, Time.now)
      unapproved_user
    end

    def update_request(user)
      patch :update, id: user.id,
                     user: {
                       first_name: user.first_name,
                       last_name: user.last_name,
                       language: user.language,
                       role_id: user.role.id,
                       email: user.email
                     }
    end

    setup do
      sign_in(users(:users_001))
    end

    test 'approves user' do
      unapproved_user = set_unapproved_user

      assert !unapproved_user.active_for_authentication?

      update_request(unapproved_user)

      unapproved_user.reload
      assert_nil unapproved_user.signup_at
      assert unapproved_user.active_for_authentication?

      assert_redirected_to backend_registrations_path
    end

    test 'notifies approved user by email' do
      unapproved_user = set_unapproved_user
      assert_difference 'ActionMailer::Base.deliveries.size', +1 do
        update_request(unapproved_user)
      end

      mail = ActionMailer::Base.deliveries.last
      assert_equal unapproved_user.email, mail.to[0]
    end
  end
end
