require 'test_helper'

module Onoma
  class VarietyTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    test 'parent_variety does not raise error when unknown variety reference is provided' do
      assert_nothing_raised { Onoma::Variety.parent_variety(:unknown_variety_name) }
      assert_nil Onoma::Variety.parent_variety(:unknown_variety_name)
    end

    test "parent_variety returns the provided variety's name if it has no parent" do
      assert_equal 'product', Onoma::Variety.parent_variety(:product)
    end

    test 'parent_variety returns the most distant and not generic parent' do
      assert_equal 'fungus', Onoma::Variety.parent_variety(:uncinula_necator)
      assert_equal 'bioproduct', Onoma::Variety.find(:fungus).parent.name
    end
  end
end
