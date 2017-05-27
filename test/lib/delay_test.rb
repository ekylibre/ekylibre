# encoding: UTF-8

require 'test_helper'

class DelayTest < ActiveSupport::TestCase
  setup do
    @date = Date.civil(2016, 5, 12)
  end

  test 'delay correctly computes' do
    delay = Delay.new '1 day'
    assert_equal Date.civil(2016, 5, 13), delay.compute(@date)
  end

  test 'delay with multiple steps correctly computes' do
    delay = Delay.new '5 days, 2 years ago'
    assert_equal Date.civil(2014, 5, 17), delay.compute(@date)
  end

  test 'delay raises error when given incorrect steps' do
    assert_raise(InvalidDelayExpression) { Delay.new '454364' }
  end

  test 'delay handles \'negative\' steps' do
    delay = Delay.new '1 day ago'
    assert_equal Date.civil(2016, 5, 11), delay.compute(@date)
  end

  test 'delay steps can be expressed in french' do
    delay = Delay.new '1 jour avant'
    assert_equal Date.civil(2016, 5, 11), delay.compute(@date)
  end

  test 'delay should be able to handle month-boundaries jumps' do
    delay = Delay.new 'eom'
    assert_equal Date.civil(2016, 5, 31), delay.compute(@date)

    delay = Delay.new '1 day, eom'
    assert_equal Date.civil(2016, 5, 31), delay.compute(@date)

    delay = Delay.new 'bom'
    assert_equal Date.civil(2016, 5, 1), delay.compute(@date)

    delay = Delay.new '1 day, bom'
    assert_equal Date.civil(2016, 5, 1), delay.compute(@date)
  end

  test 'new delay without any parameters should be an empty delay' do
    delay = Delay.new
    assert_equal @date, delay.compute(@date)
  end

  test 'new delay with an empty string should be an empty delay' do
    delay = Delay.new ''
    assert_equal @date, delay.compute(@date)
  end

  test 'delays can be inverted' do
    forwards = Delay.new '1 day'
    backwards = Delay.new '1 day ago'

    assert_equal forwards.invert.compute(@date), backwards.compute(@date)

    forwards = Delay.new 'eom'
    backwards = Delay.new 'bom'

    assert_equal forwards.invert.compute(@date), backwards.compute(@date)
  end

  test 'delays can be summed with other delays' do
    first_d = Delay.new '1 day'
    second_d = Delay.new '2 days'
    sum = first_d + second_d

    expected_result = Delay.new '3 days'

    assert_equal expected_result.compute(@date), sum.compute(@date)
  end

  test 'delays can be summed with a delay expression' do
    first_d = Delay.new '1 day'
    second_d = '2 days'
    sum = first_d + second_d

    expected_result = Delay.new '3 days'

    assert_equal expected_result.compute(@date), sum.compute(@date)
  end

  test 'delays can be summed with a number of seconds' do
    first_d = Delay.new '1 day'
    second_d = 10
    sum = first_d + second_d

    expected_result = Delay.new '1 day, 10 seconds'

    assert_equal expected_result.compute(@date), sum.compute(@date)
  end

  test 'delays can be summed with a Measure' do
    first_d = Delay.new '1 day'
    second_d = 10.in :hour
    sum = first_d + second_d

    expected_result = Delay.new '1 day, 10 hours'

    assert_equal expected_result.compute(@date), sum.compute(@date)
  end

  test 'delays sum with something unknown should raise an error' do
    assert_raise(ArgumentError) { Delay.new('1 day') + ['Hello'] }
  end

  test 'delays can be subtracted by other delays' do
    first_d = Delay.new '3 days'
    second_d = Delay.new '2 days'
    sum = first_d - second_d

    expected_result = Delay.new '1 day'

    assert_equal expected_result.compute(@date), sum.compute(@date)
  end

  test 'delays can be subtracted by a delay expression' do
    first_d = Delay.new '3 days'
    second_d = '2 days'
    sum = first_d - second_d

    expected_result = Delay.new '1 day'

    assert_equal expected_result.compute(@date), sum.compute(@date)
  end

  test 'delays can be substracted by a number of seconds' do
    first_d = Delay.new '1 day'
    second_d = 10
    sum = first_d - second_d

    expected_result = Delay.new '1 day, 10 seconds ago'

    assert_equal expected_result.compute(@date), sum.compute(@date)
  end

  test 'delays can be subtracted by a Measure' do
    first_d = Delay.new '1 day'
    second_d = 10.in :hour
    sum = first_d - second_d

    expected_result = Delay.new '1 day, 10 hours ago'

    assert_equal expected_result.compute(@date), sum.compute(@date)
  end

  test 'delays subtraction with something unknown should raise an error' do
    assert_raise(ArgumentError) { Delay.new('1 day') - ['Hello'] }
  end
end
