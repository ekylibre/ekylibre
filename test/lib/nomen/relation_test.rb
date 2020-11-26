require 'test_helper'

module Onoma
  class RelationTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    setup do
      I18n.locale = ENV['LOCALE']
    end

    test 'detect' do
      relation = Onoma::Dimension.list
      x = relation.detect do |i|
        assert_equal Onoma::Item, i.class
        i.name == 'distance'
      end
      assert_equal Onoma::Item, x.class
    end

    test 'select' do
      relation = Onoma::Dimension.list
      l = relation.select do |i|
        assert_equal Onoma::Item, i.class
      end
      assert_equal Onoma::Relation, l.class
    end

    test 'collect' do
      relation = Onoma::Dimension.list
      l = relation.collect do |i|
        assert_equal Onoma::Item, i.class
      end
      assert_equal Array, l.class
    end
  end
end
