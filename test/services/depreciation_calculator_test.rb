require 'test_helper'

class DepreciationCalculatorTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  setup do
    FinancialYear.delete_all
  end

  [
    [Date.new(2015, 1, 1), Date.new(2015, 12, 31), 1],
    [Date.new(2015, 5, 1), Date.new(2016, 4, 30), 5],
    [Date.new(2015, 5, 1), Date.new(2016, 12, 31), 1],
    [Date.new(2015, 9, 1), Date.new(2016, 12, 31), 1]
  ].each_with_index do |e, i|
    start_date, end_date, exp_month = e
    test "guess the correct starting day of the financial year N°#{i}" do
      fy = FinancialYear.create! started_on: start_date, stopped_on: end_date
      calc = DepreciationCalculator.new fy, nil

      fy_start = calc.financial_year_start_day
      assert_equal 1, fy_start.day
      assert_equal exp_month, fy_start.month
    end
  end

  test 'computes the correct number of periods' do
    calc = DepreciationCalculator.new nil, nil

    months = calc.monthly_periods Date.new(2015, 1, 1), 20
    assert_equal 60, months.length
    months.each do |started, stopped, dur|
      assert_equal 1, started.day
      assert_equal stopped, stopped.end_of_month
      assert_equal 30, dur
    end
  end

  test 'handles correctly depreciations that dont start at the begining of the month' do
    calc = DepreciationCalculator.new nil, nil

    months = calc.monthly_periods Date.new(2015, 1, 25), 20
    assert_equal 61, months.length
    assert_equal 5 * 360, months.map(&:third).reduce(&:+), "The sum of all months does not add up the the depreciation period"
  end

  test 'the months are grouped in periods in sync with the dates of the reference FinancialYear given' do
    fy_reference = FinancialYear.create started_on: Date.new(2015, 3, 1), stopped_on: Date.new(2016, 2, 28)

    calc = DepreciationCalculator.new fy_reference, :yearly
    periods = calc.depreciation_period Date.new(2015, 1, 25), 20

    assert_equal 6, periods.length
    assert_equal 5 * 360, periods.map(&:third).reduce(&:+), "The sum of all months does not add up the the depreciation period"
    assert_equal Date.new(2015, 1, 25), periods.first.first
    assert_equal Date.new(2015, 2, 28), periods.first.second
  end
end
