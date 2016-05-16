require 'test_helper'

module Nomen
  class RelationTest < ActiveSupport::TestCase
    setup do
      I18n.locale = ENV['LOCALE']
    end

    test 'detect' do
      relation = Nomen::Dimension.list
      x = relation.detect do |i|
        assert_equal Nomen::Item, i.class
        i.name == 'distance'
      end
      assert_equal Nomen::Item, x.class
    end

    test 'select' do
      relation = Nomen::Dimension.list
      l = relation.select do |i|
        assert_equal Nomen::Item, i.class
      end
      assert_equal Nomen::Relation, l.class
    end

    test 'collect' do
      relation = Nomen::Dimension.list
      l = relation.collect do |i|
        assert_equal Nomen::Item, i.class
      end
      assert_equal Array, l.class
    end
  end
end
