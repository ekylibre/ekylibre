require 'test_helper'

module Nomen
  class VarietyTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures

    test 'parent_variety does not raise error when unknown variety reference is provided' do
      assert_nothing_raised { Nomen::Variety.parent_variety(:unknown_variety_name) }
      assert_nil Nomen::Variety.parent_variety(:unknown_variety_name)
    end

    test "parent_variety returns the provided variety's name if it has no parent" do
      assert_equal 'product', Nomen::Variety.parent_variety(:product)
    end

    test 'parent_variety returns the most distant and not generic parent' do
      assert_equal 'fungus', Nomen::Variety.parent_variety(:uncinula_necator)
      assert_equal 'bioproduct', Nomen::Variety.find(:fungus).parent.name
    end
  end
end
