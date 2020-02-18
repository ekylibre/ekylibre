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
# == Table: sequences
#
#  created_at       :datetime         not null
#  creator_id       :integer
#  id               :integer          not null, primary key
#  last_cweek       :integer
#  last_month       :integer
#  last_number      :integer
#  last_year        :integer
#  lock_version     :integer          default(0), not null
#  name             :string           not null
#  number_format    :string           not null
#  number_increment :integer          default(1), not null
#  number_start     :integer          default(1), not null
#  period           :string           default("number"), not null
#  updated_at       :datetime         not null
#  updater_id       :integer
#  usage            :string
#

require 'test_helper'

class SequenceTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  test 'next values' do
    sequence = Sequence.find_by(usage: :sales_invoices)
    sequence.update_attributes!(number_format: 'Y[year]M[month]N[number|8]', period: :month)

    val1 = sequence.next_value
    val2 = sequence.next_value!
    assert_equal val1, val2
  end

  test 'reset' do
    sequence = Sequence.find_by(usage: :sales_invoices)
    sequence.update_attributes!(number_format: 'Y[year]M[month]N[number|8]', period: :month)

    sequence.next_value!
    val1 = sequence.last_number
    sequence.next_value!
    assert_equal val1 + 1, sequence.last_number
    sequence.next_value!
    sequence.next_value!
    sequence.next_value!
    sequence.next_value!
    future = Date.today >> 1
    value = sequence.next_value(future)
    assert_equal "Y#{future.year}M#{future.month}N00000001", value
  end

  test 'incrementation' do
    sequence = Sequence.find_by(usage: 'entities')
    sequence.update!(last_number: 99_990_000, number_format: '[number|8]', period: :none)
    assert_equal '99990001', sequence.next_value!
    assert_equal '99990002', sequence.next_value!
    assert_equal '99990003', sequence.next_value!
  end

  test 'concurrent affectation' do
    sequence = Sequence.find_by(usage: 'entities')
    sequence.update!(last_number: 99_000_000, number_format: '[number|8]', period: :none)
    assert_equal Entity.sequence_manager.sequence, sequence
    assert_equal '99000001', sequence.next_value
    assert_equal '99000001', Entity.sequence_manager.unique_predictable
    assert_equal '99000001', sequence.next_value
    assert_nil Entity.find_by(number: '99000001'), 'Entity 99 000 001 should not be here. Find a new number for the test.'
    entity = Entity.create!(last_name: 'First person')
    assert_equal '99000001', entity.number
    entity = Entity.create!(last_name: 'Second person')
    assert_equal '99000002', entity.number
    entity = Entity.create!(last_name: 'Third person')
    assert_equal '99000003', entity.number
    Sequence.where(usage: 'entities').update_all(last_number: 99_100_000)
    entity = Entity.create!(last_name: 'Fourth person')
    assert_equal '99100001', entity.number
  end

  test 'can handle usage changes on sequences' do
    sequence = Sequence.find_by(usage: :purchases) ||
      Sequence.create!(name: 'PurchasesTest', usage: :purchases, number_format: 'A[number|12]')
    assert_equal sequence, Purchase.sequence_manager.sequence

    Sequence.find_by(usage: :affairs).destroy!
    sequence.update!(usage: :affairs)
    sequence_replacement = Sequence.create!(name: 'PurchaseTestBis', usage: :purchases, number_format: 'YOLO[number|6]')
    assert_equal sequence_replacement, Purchase.sequence_manager.sequence
  end

  test 'can handle tenant switching' do
    sequence = Sequence.find_by(usage: :purchases) ||
      Sequence.create!(name: 'PurchasesTest', usage: :purchases, number_format: 'A[number|12]')

    assert_equal sequence, Purchase.sequence_manager.sequence

    Ekylibre::Tenant.create :sequence_test
    Ekylibre::Tenant.switch :sequence_test do

      sequence_with_same_id = Sequence.find_by(usage: :affairs) ||
        Sequence.create!(name: 'PurchasesBis', usage: :affairs, number_format: 'YOLO[number|6]')

      until sequence_with_same_id.id == sequence.id
        sequence_with_same_id.destroy!
        sequence_with_same_id = Sequence.create!(name: 'NotPurchases', usage: :affairs, number_format: 'YOLO[number|6]')
      end

      sequence_other_tenant = Sequence.find_by(usage: :purchases) ||
        Sequence.create!(name: 'PurchasesBis', usage: :purchases, number_format: 'A[number|12]')

      until sequence_other_tenant.id != sequence.id
        sequence_other_tenant.destroy!
        sequence_other_tenant = Sequence.create!(name: 'PurchasesBis', usage: :purchases, number_format: 'A[number|12]')
      end

      assert_equal sequence_other_tenant, Purchase.sequence_manager.sequence
    end
  end
end
