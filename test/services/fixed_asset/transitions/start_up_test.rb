require 'test_helper'
require_dependency Rails.root.join('app', 'models', 'fixed_asset')

class FixedAsset
  module Transitions
    class StartUpTest < Ekylibre::Testing::ApplicationTestCase

      setup do
        create :financial_year, year: 2016
      end

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

      test "when importing a fixed_asset, the journal_entry is printed_on a the begining of the financial year" do
        fa = create :fixed_asset,
                    started_on: Date.new(2015, 5, 8)

        assert fa.start_up
        assert_equal Date.new(2016, 1, 1), fa.journal_entry.printed_on
      end

      private

        def new_transition_for(fa)
          FixedAsset::Transitions::StartUp.new(fa)
        end
    end
  end
end
