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
# == Table: users
#
#  administrator                          :boolean          default(FALSE), not null
#  authentication_token                   :string
#  commercial                             :boolean          default(FALSE), not null
#  confirmation_sent_at                   :datetime
#  confirmation_token                     :string
#  confirmed_at                           :datetime
#  created_at                             :datetime         not null
#  creator_id                             :integer
#  current_sign_in_at                     :datetime
#  current_sign_in_ip                     :string
#  description                            :text
#  email                                  :string           not null
#  employed                               :boolean          default(FALSE), not null
#  employment                             :string
#  encrypted_password                     :string           default(""), not null
#  failed_attempts                        :integer          default(0)
#  first_name                             :string           not null
#  id                                     :integer          not null, primary key
#  invitation_accepted_at                 :datetime
#  invitation_created_at                  :datetime
#  invitation_limit                       :integer
#  invitation_sent_at                     :datetime
#  invitation_token                       :string
#  invitations_count                      :integer          default(0)
#  invited_by_id                          :integer
#  language                               :string           not null
#  last_name                              :string           not null
#  last_sign_in_at                        :datetime
#  last_sign_in_ip                        :string
#  lock_version                           :integer          default(0), not null
#  locked                                 :boolean          default(FALSE), not null
#  locked_at                              :datetime
#  maximal_grantable_reduction_percentage :decimal(19, 4)   default(5.0), not null
#  person_id                              :integer
#  provider                               :string
#  remember_created_at                    :datetime
#  reset_password_sent_at                 :datetime
#  reset_password_token                   :string
#  rights                                 :text
#  role_id                                :integer
#  sign_in_count                          :integer          default(0)
#  signup_at                              :datetime
#  team_id                                :integer
#  uid                                    :string
#  unconfirmed_email                      :string
#  unlock_token                           :string
#  updated_at                             :datetime         not null
#  updater_id                             :integer
#
require 'test_helper'

class UserTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  test 'preferences' do
    user = User.first
    user.prefer!('something', 'foo')
    assert_equal 1, user.preferences.where(name: 'something').count
    user.prefer!('something', 'bar')
    assert_equal 1, user.preferences.where(name: 'something').count
  end
end
