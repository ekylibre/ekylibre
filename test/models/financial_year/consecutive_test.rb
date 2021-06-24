require 'test_helper'

module FinancialYearTest
  class ConsecutiveTest < Ekylibre::Testing::ApplicationTestCase
    setup do
      FinancialYear.delete_all

      FinancialYear.create! started_on: '2018-07-08', stopped_on: '2019-06-30'
    end

    cases = [
      # started_on, stopped_on, expected
      ['2019-07-01', '2020-06-30', true],
      ['2019-07-02', '2020-06-30', false],
      ['2019-08-01', '2020-06-30', false]
    ]

    cases.each_with_index do |(started_on, stopped_on, expected), index|
      test "FinancialYears have to be consecutive (case #{index})" do
        fy = FinancialYear.new(started_on: started_on, stopped_on: stopped_on)

        assert_equal expected, fy.save
      end
    end
  end
end
