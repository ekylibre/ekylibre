require 'test_helper'

module Ekylibre
  class BestOfTheWorldExchanger < ActiveExchanger::Base
  end
end

module ActiveExchanger
  class BaseTest < ActiveSupport::TestCase
    test 'naming' do
      assert_equal :ekylibre_best_of_the_world, Ekylibre::BestOfTheWorldExchanger.exchanger_name
    end

    test 'deprecation' do
      class BasicExchanger < ActiveExchanger::Base
        self.deprecated = true
      end

      assert BasicExchanger.deprecated?

      class BasicChildExchanger < BasicExchanger
      end

      class OtherExchanger < ActiveExchanger::Base
      end

      assert BasicExchanger.deprecated?
      refute OtherExchanger.deprecated?

      assert ActiveExchanger::Base.importers_selection.any?
    end
  end
end
