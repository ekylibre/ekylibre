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
# == Table: product_nature_variant_valuings
#
#  amount              :decimal(19, 4)   not null
#  average_cost_amount :decimal(19, 4)   not null
#  computed_at         :datetime         not null
#  created_at          :datetime         not null
#  creator_id          :integer
#  id                  :integer          not null, primary key
#  lock_version        :integer          default(0), not null
#  updated_at          :datetime         not null
#  updater_id          :integer
#  variant_id          :integer          not null
#
require 'test_helper'

class ProductNatureVariantValuingTest < ActiveSupport::TestCase
  test_model_actions
  def setup
    @valuing = ProductNatureVariantValuing.create!(amount: 100, average_cost_amount: 5, variant_id: 1, computed_at: Time.new(1, 1, 1).in_time_zone)
  end

  static_value = {
    unitary_price: 15,
    quantity_action: 10,
    quantity_entry: 50,
    quantity_new: 50,
    computed_at: Time.new(1, 1, 1).in_time_zone
  }

  test 'invalid without amount / average_cost_amount' do
    @valuing.amount = nil
    refute @valuing.valid?, 'valuing is valid without amount'
    assert_not_nil @valuing.errors[:amount], 'no validation error for amount present'
    @valuing.average_cost_amount = nil
    refute @valuing.valid?, 'valuing is valid without amount'
    assert_not_nil @valuing.errors[:average_cost_amount], 'no validation error for average_cost_amount present'
  end

  test 'create' do
    assert @valuing.save
  end

  test 'method calculate_first_entrance' do
    refute_nil ProductNatureVariantValuing.calculate_first_entrance(static_value[:unitary_price], static_value[:quantity_action], static_value[:quantity_new], @valuing.variant_id)
    assert ProductNatureVariantValuing.calculate_first_entrance(static_value[:unitary_price], static_value[:quantity_action], static_value[:quantity_new], @valuing.variant_id)

    valuing = ProductNatureVariantValuing.calculate_first_entrance(static_value[:unitary_price], static_value[:quantity_new], static_value[:quantity_action], @valuing.variant_id)
    assert_equal valuing.amount, 150
    assert_equal valuing.average_cost_amount, 3
  end

  test 'method calculate_output' do
    assert_equal @valuing.amount, 100
    valuing = ProductNatureVariantValuing.calculate_output(static_value[:unitary_price], static_value[:quantity_new], static_value[:quantity_action], @valuing.variant_id)
    assert_equal valuing.amount, 250
    assert_equal valuing.average_cost_amount, 5
    refute_nil ProductNatureVariantValuing.calculate_output(static_value[:unitary_price], static_value[:quantity_new], static_value[:quantity_action], @valuing.variant_id)
    assert ProductNatureVariantValuing.calculate_output(static_value[:unitary_price], static_value[:quantity_new], static_value[:quantity_action], @valuing.variant_id)
  end

  test 'method calculate_input' do
    valuing = ProductNatureVariantValuing.calculate_input(static_value[:quantity_new], static_value[:quantity_action], @valuing.variant_id)
    assert_equal valuing.amount, 50
    assert_equal valuing.average_cost_amount, 1
    refute_nil ProductNatureVariantValuing.calculate_input(static_value[:quantity_new], static_value[:quantity_action], @valuing.variant_id)
    assert ProductNatureVariantValuing.calculate_input(static_value[:quantity_new], static_value[:quantity_action], @valuing.variant_id)
  end

  test 'method calculate_inventory' do
    valuing = ProductNatureVariantValuing.calculate_inventory(static_value[:quantity_entry], @valuing.variant_id)
    assert_equal valuing.amount, 250
    assert_equal valuing.average_cost_amount, 5
    refute_nil ProductNatureVariantValuing.calculate_inventory(static_value[:quantity_entry], @valuing.variant_id)
    assert ProductNatureVariantValuing.calculate_inventory(static_value[:quantity_entry], @valuing.variant_id)
  end
end
