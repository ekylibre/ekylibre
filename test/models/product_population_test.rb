# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
# == Table: product_populations
#
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  product_id   :integer
#  started_at   :datetime         not null
#  stopped_at   :datetime
#  updated_at   :datetime         not null
#  updater_id   :integer
#  value        :decimal(19, 4)
#
require 'test_helper'

class ProductPopulationTest < ActiveSupport::TestCase
  test_model_actions

  test 'population gets updated on move!' do
    product = products(:matters_001)
    initial_population = product.population
    quantity = 5.in_ton.to_d

    product.move! quantity, at: Time.now.utc

    assert_equal initial_population + quantity, product.population
  end

  test 'population change in the future doesn\'t impact current population' do
    product = products(:matters_001)
    initial_population = product.population
    quantity = 5.in_ton.to_d

    product.move! quantity, at: Time.now.utc + 15.days

    assert_equal initial_population, product.population
  end

  test 'population gets updated correctly if two moves are simultaneous' do
    product = products(:matters_001)
    initial_population = product.population
    time = Time.now.utc

    product.move! 5.in_ton.to_d, at: time
    product.move! 3.in_ton.to_d, at: time

    assert_equal initial_population + 8.in_ton.to_d, product.population
  end

  test 'population doesn\'t change when movement is moved earlier in time' do
    product = products(:matters_001)
    quantity = 5.in_ton.to_d

    product.move! quantity, at: Time.now.utc - 1.day
    initial_population = product.population
    product.movements.first.update started_at: Time.now.utc - 2.days

    assert_equal initial_population, product.population
  end

  test 'population goes back to initial if two movement is moved to future' do
    product = products(:matters_001)
    quantity = 5.in_ton.to_d
    initial_population = product.population

    product.move! quantity, at: Time.now.utc - 1.day
    product.movements.first.update started_at: Time.now.utc + 1.day

    assert_equal initial_population, product.population
  end
end
