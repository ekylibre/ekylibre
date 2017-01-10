# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# == Table: preferences
#
#  boolean_value     :boolean
#  created_at        :datetime         not null
#  creator_id        :integer
#  decimal_value     :decimal(19, 4)
#  id                :integer          not null, primary key
#  integer_value     :integer
#  lock_version      :integer          default(0), not null
#  name              :string           not null
#  nature            :string           not null
#  record_value_id   :integer
#  record_value_type :string
#  string_value      :text
#  updated_at        :datetime         not null
#  updater_id        :integer
#  user_id           :integer
#

require 'test_helper'

class PreferenceTest < ActiveSupport::TestCase
  test_model_actions
  test 'creating boolean preference' do
    p = Preference.set!('my.boolean.preference', true)
    assert p
    assert p.boolean?, "Expect to find boolean. Got: #{p.nature.inspect}"
    assert p.value
  end

  test 'creating record preference' do
    account = Account.first
    assert account
    p = Preference.set!('my.record.preference', account)
    assert p
    assert p.record?, "Expect to find record. Got: #{p.nature.inspect}"
    assert p.value
  end

  test 'creating STI record preference' do
    animal = Animal.first
    assert animal
    p = Preference.set!('my.animal.preference', animal)
    assert p
    assert p.record?, "Expect to find record. Got: #{p.nature.inspect}"
    assert p.value
    assert_equal 'Product', p.record_value_type
  end

  test 'getting values' do
    assert_equal 0, Preference.where(name: 'mybooboolean').count
    assert Preference.value('mybooboolean', true)
    assert_equal 1, Preference.where(name: 'mybooboolean').count
    assert Preference.value('mybooboolean', false)
    assert_equal 1, Preference.where(name: 'mybooboolean').count
    assert_not Preference.value('myfalsebooboolean', false)
  end

  test 'concurrency' do
    preference_1 = Preference.get('myfavoritepref', 'foo')
    preference_2 = Preference.find(preference_1.id)

    preference_1.set! 'bar'

    preference_2.set! 'baz'

    assert_equal 'baz', Preference.value('myfavoritepref', 'qux')
  end

  test 'optimistic locking absence' do
    preference_1 = Preference.get('myfavoritepref', 'foo')
    preference_2 = Preference.find(preference_1.id)

    preference_2.value = 'yeah!'
    preference_2.save!

    preference_1.value = 'yo!'
    preference_1.save!

    assert_equal 'yo!', Preference.value('myfavoritepref', 'qux')
  end
end
