require 'test_helper'
require_dependency Rails.root.join('app', 'models', 'fixed_asset')

class FixedAsset
  module Transitions
    class SellTest < Ekylibre::Testing::ApplicationTestCase

      setup do
        @fy = create :financial_year, year: 2018
      end

      test 'should not be able to sell FixedAsset that are not in use' do
        supported_state = 'in_use'
        unsupported_states = FixedAsset.state.values.reject { |state| state == supported_state }
        unsupported_states.each do |state|
          mock = Minitest::Mock.new
          mock.expect :state, state
          mock.expect :sold_on, nil

          t = new_transition_for mock

          assert_not t.can_run?, "Should not be able to sell a FixedAsset with state #{state}"
          assert_mock mock
        end
      end

      test 'should not allow to sell an invalid fixed_asset' do
        mock = Minitest::Mock.new
        mock.expect :state, :in_use
        mock.expect :valid?, false
        mock.expect :sold_on, nil

        t = new_transition_for mock

        assert_not t.can_run?, "Should not be able to scrap an invalid fixed_asset"
        assert_mock mock
      end

      test 'cannot sell a FixedAsset if the given scrapped_on date is not during an opened FinancialYear' do
        mock = Minitest::Mock.new
        mock.expect :state, :in_use
        mock.expect :valid?, true
        mock.expect :sold_on, nil

        t = new_transition_for mock, sold_on: Date.new(2019, 5, 1)

        assert_not t.can_run?
        assert_mock mock
      end

      def new_transition_for(fa, **options)
        FixedAsset::Transitions::Sell.new(fa, **options)
      end
    end
  end
end
