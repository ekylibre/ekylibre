require 'test_helper'

module ActiveExchanger
  class CsvParserTest < Ekylibre::Testing::ApplicationTestCase
    test 'transform works as expected' do
      parser = CsvParser.new([])
      assert_equal Date.new(2019, 12, 12), parser.transform("2019-12-12", :date)
      assert_equal 14, parser.transform("14", :integer)
      assert_equal 1.5, parser.transform("1,5", :float)
      assert_equal 1.5, parser.transform("1.5", :float)
      assert_equal "test", parser.transform("test", :string)
      assert_equal "n3#7", parser.transform('n3#7', :efvbf)
    end

    test 'validate works as expected' do
      parser = CsvParser.new([])
      assert_equal true, parser.validate("2019-12-12", :not_nil)
      assert_equal false, parser.validate(nil, :not_nil)
      assert_equal true, parser.validate("133", :not_nil)
      assert_equal false, parser.validate("3", :greater_or_equal_to_zero)
      assert_equal false, parser.validate(-3, :greater_or_equal_to_zero)
    end
  end
end
