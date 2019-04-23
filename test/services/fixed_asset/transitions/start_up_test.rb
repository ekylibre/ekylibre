require 'test_helper'
require_dependency Rails.root.join('app', 'models', 'fixed_asset')

class FixedAsset
  module Transitions
    class StartUpTest < Ekylibre::Testing::ApplicationTestCase

      test 'should not be able to start FixedAsset that are not drafts' do
        supported_state = 'draft'
        unsupported_states = FixedAsset.state.values.reject { |state| state == supported_state }
        unsupported_states.each do |state|
          mock = Minitest::Mock.new
          mock.expect :state, state

          transition = new_transition_for mock

          assert_not transition.can_run?, "Should not be able to run on a FixedAsset with state '#{state}'"
          assert_mock mock
        end
      end

      test 'should not be able start_up a fixed_asset if it is not in a valid state' do
        mock = Minitest::Mock.new
        mock.expect :state, :draft
        mock.expect :valid?, false

        transition = new_transition_for mock
        assert_not transition.can_run?
        assert_mock mock
      end

      private

        def new_transition_for(fa)
          FixedAsset::Transitions::StartUp.new(fa)
        end
    end
  end
end
