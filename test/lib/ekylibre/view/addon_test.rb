require 'test_helper'

module Ekylibre
  module View
    class AddonTest < ActiveSupport::TestCase
      test 'add' do
        Ekylibre::View::Addon.list

        Ekylibre::View::Addon.add(:weird, 'path/to/first')

        assert_equal 1, Ekylibre::View::Addon.list['weird'].size

        Ekylibre::View::Addon.add(:weird, 'path/to/second')

        assert_equal 2, Ekylibre::View::Addon.list['weird'].size
        assert_equal 'path/to/second', Ekylibre::View::Addon.list['weird'].last.partial
      end
    end
  end
end
