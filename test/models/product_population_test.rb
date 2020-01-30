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
# == Table: product_populations
#
#  created_at   :datetime
#  creator_id   :integer
#  id           :integer          primary key
#  lock_version :integer
#  product_id   :integer
#  started_at   :datetime
#  updated_at   :datetime
#  updater_id   :integer
#  value        :decimal(, )
#
require 'test_helper'

class ProductPopulationTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions

  setup do
    @product = products(:matters_001)
    @initial_population = @product.population
    @quantity = 5.in_ton.to_d
    @time = Time.now.utc
  end

  test 'population gets updated on move!' do
    @product.move! @quantity, at: @time

    assert_equal @initial_population + @quantity, @product.population
  end

  test 'population change in the future doesn\'t impact current population' do
    @product.move! @quantity, at: @time + 15.days

    assert_equal @initial_population, @product.population
  end

  test 'population gets updated correctly if moves are simultaneous' do
    moves = [5, 3, 4, 2]
    moves.each do |quantity|
      @product.move! quantity.in_ton.to_d, at: @time
    end

    assert_equal @initial_population + moves.sum.in_ton.to_d, @product.population
  end

  test 'population doesn\'t change when movement is moved earlier in time' do
    move = @product.move! @quantity, at: @time - 1.day
    @initial_population = @product.population

    move.update started_at: @time - 2.days

    assert_equal @initial_population, @product.population
  end

  test 'population goes back to initial if two movement is moved to future' do
    move = @product.move! @quantity, at: @time - 1.day
    move.update started_at: @time + 1.day

    assert_equal @initial_population, @product.population
  end

  test 'population is correctly updated when movement is moved to same time as an existing movement' do
    @product.move! 5.in_ton.to_d, at: @time
    move = @product.move! 3.in_ton.to_d, at: @time + 1.day

    move.update(started_at: @time)

    assert_equal @initial_population + 8.in_ton.to_d, @product.population
  end

  test 'population is correctly updated when movement is destroyed' do
    move = @product.move! 5.in_ton.to_d, at: @time - 1.day
    move.destroy

    assert_equal @initial_population, @product.population
  end

  test 'population is correctly updated when one of the simultaneous movements is destroyed' do
    @product.move! 5.in_ton.to_d, at: @time
    first_population = @product.population
    move = @product.move! 3.in_ton.to_d, at: @time

    move.destroy

    assert_equal first_population, @product.population
  end

  test 'population is updated when a movement is moved around another movement' do
    @product.move! 5.in_ton.to_d, at: @time - 2.days
    move = @product.move! 3.in_ton.to_d, at: @time - 1.day
    @initial_population = @product.population

    # Moving it before
    move.update(started_at: @time - 3.days)
    assert_equal @initial_population, @product.population

    # Moving it after
    move.update(started_at: @time - 1.day)
    assert_equal @initial_population, @product.population
  end

  test 'populations after simultaneous movements are correct' do
    @product.move! 5.in_ton.to_d, at: @time - 2.days
    @product.move! 3.in_ton.to_d, at: @time - 2.days
    @initial_population = @product.population

    @product.move! 4.in_ton.to_d, at: @time - 1.day

    assert_equal @initial_population + 4.in_ton.to_d, @product.population
  end

  test 'populations after both simultaneous movements and distinctly-timed ones are correct' do
    @product.move! 5.in_ton.to_d, at: @time - 1.day
    @product.move! 3.in_ton.to_d, at: @time - 1.day
    @initial_population = @product.population

    @product.move! 4.in_ton.to_d, at: @time - 2.days

    assert_equal @initial_population + 4.in_ton.to_d, @product.population
  end
end
