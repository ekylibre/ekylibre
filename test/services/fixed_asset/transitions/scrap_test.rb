require 'test_helper'
require_dependency Rails.root.join('app', 'models', 'fixed_asset')

class FixedAsset
  module Transitions
    class ScrapTest < Ekylibre::Testing::ApplicationTestCase

      setup do
        @fy = create :financial_year, year: 2018
      end

      test 'should not be able to scrap FixedAsset that are not in use' do
        supported_state = 'in_use'
        unsupported_states = FixedAsset.state.values.reject { |state| state == supported_state }
        unsupported_states.each do |state|
          mock = Minitest::Mock.new
          mock.expect :state, state
          mock.expect :scrapped_on, nil

          scrapper = new_transition_for mock

          assert_not scrapper.can_run?, "Should not be able to scrap a FixedAsset with state #{state}"
          assert_mock mock
        end
      end

      test 'should not allow to scrap an invalid fixed_asset' do
        mock = Minitest::Mock.new
        mock.expect :state, :in_use
        mock.expect :valid?, false
        mock.expect :scrapped_on, nil

        t = new_transition_for mock

        assert_not t.can_run?, "Should not be able to scrap an invalid fixed_asset"
        assert_mock mock
      end

      test 'cannot scrap a FixedAsset if the given scrapped_on date is not during an opened FinancialYear' do
        mock = Minitest::Mock.new
        mock.expect :state, :in_use
        mock.expect :valid?, true
        mock.expect :scrapped_on, nil

        t = new_transition_for mock, scrapped_on: Date.new(2019, 5, 1)

        assert_not t.can_run?
        assert_mock mock
      end

      test 'should change the state of the fixed_asset and bookkeep correctly the depreciations records' do
        exceptional_expenses_account = Account.find_or_import_from_nomenclature :exceptional_depreciations_imputations_expenses_for_fixed_assets
        scrapped_on = Date.new(2018, 9, 5)
        fa = create :fixed_asset, :in_use, :monthly,
                    started_on: Date.new(2018, 1, 1)
        t = new_transition_for fa, scrapped_on: scrapped_on

        # byebug
        assert t.run, t_err(t)

        assert_equal 'scrapped', fa.state
        assert_equal Date.new(2018, 9, 5), fa.scrapped_on
        assert fa.depreciations.all? &:has_journal_entry?

        before_scrap = fa.reload.depreciations.up_to scrapped_on
        assert_equal scrapped_on, before_scrap.last.stopped_on
        assert_equal scrapped_on, before_scrap.last.journal_entry.printed_on
        before_scrap.each { |d| assert_equal fa.expenses_account, d.journal_entry.items.debit.first.account }

        after_scrap = fa.depreciations.following(before_scrap.last)
        assert_equal fa.depreciations.count, before_scrap.count + after_scrap.count
        after_scrap.each { |d| assert_equal exceptional_expenses_account, d.journal_entry.items.debit.first.account }
        after_scrap.each { |d| assert_equal scrapped_on, d.journal_entry.printed_on }
      end

      def new_transition_for(fa, **options)
        FixedAsset::Transitions::Scrap.new(fa, **options)
      end

      def t_err(t)
        proc { raise t.error }
      end
    end
  end
end
