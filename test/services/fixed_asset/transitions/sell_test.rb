require 'test_helper'
require_dependency Rails.root.join('app', 'models', 'fixed_asset')

class FixedAsset
  module Transitions
    class SellTest < Ekylibre::Testing::ApplicationTestCase
      setup do
        [2018, 2019].each { |year| create :financial_year, year: year }
        @product = create :asset_fixable_product, born_at: DateTime.new(2018, 1, 1)
        @fixed_asset = create :fixed_asset, :in_use, started_on: Date.new(2018, 1, 1), product: @product
        @sold_on = Date.new(2018, 6, 30)
      end

      test 'should not be able to sell FixedAsset that are not in use' do
        supported_state = 'in_use'
        unsupported_states = FixedAsset.state.values.reject { |state| state == supported_state }
        unsupported_states.each do |state|
          mock = Minitest::Mock.new
          mock.expect :state, state
          mock.expect :sold_on, nil

          t = new_transition_for mock, Date.new(2018, 9, 5)

          assert_not t.can_run?, "Should not be able to sell a FixedAsset with state #{state}"
          assert_mock mock
        end
      end

      test 'should not allow to sell an invalid fixed_asset' do
        mock = Minitest::Mock.new
        mock.expect :state, :in_use
        mock.expect :valid?, false
        mock.expect :sold_on, nil

        t = new_transition_for mock, Date.new(2018, 9, 5)

        assert_not t.can_run?, "Should not be able to scrap an invalid fixed_asset"
        assert_mock mock
      end

      test 'cannot sell a FixedAsset if the given scrapped_on date is not during an opened FinancialYear' do
        mock = Minitest::Mock.new
        mock.expect :state, :in_use
        mock.expect :valid?, true
        mock.expect :sold_on, nil

        t = new_transition_for mock, Date.new(2020, 5, 1)

        assert_not t.can_run?
        assert_mock mock
      end

      test "cannot sell a fixed asset if it isn't linked to a sale or a product" do
        t = new_transition_for @fixed_asset, @sold_on

        assert_not t.can_run?

        @fixed_asset.update!(product_id: nil)
        create :sale_item, :fixed, variant: @product.variant, fixed_asset: @fixed_asset
        @fixed_asset.reload

        assert_not t.can_run?

        @fixed_asset.update!(product: @product)

        assert t.can_run?
      end

      test 'selling a fixed asset sets the linked product dead_at value to sold_on date' do
        create :sale_item, :fixed, variant: @product.variant, fixed_asset: @fixed_asset
        @fixed_asset.reload

        assert_nil @product.dead_at

        t = new_transition_for @fixed_asset, @sold_on

        assert t.run, t_err(t)
        @product.reload
        assert @product.dead_at, @sold_on.to_datetime
      end

      test 'selling a fixed asset sets the state of the associated sale to invoice and invoiced_at to sold_on' do
        sale = create :sale, state: :draft
        create :sale_item, :fixed, variant: @product.variant, fixed_asset: @fixed_asset, sale: sale
        @fixed_asset.reload
        @fixed_asset.update!(sold_on: @sold_on)

        @fixed_asset.sell
        sale.reload

        assert sale.invoice?
        assert_equal sale.invoiced_at, @fixed_asset.sold_on.to_datetime
      end

      test 'selling a fixed asset generates accurate journal entries' do
        sale = create :sale, state: :draft
        create :sale_item, :fixed, variant: @product.variant, fixed_asset: @fixed_asset, sale: sale
        @fixed_asset.reload
        @fixed_asset.update!(sold_on: @sold_on)

        @fixed_asset.sell
        @fixed_asset.reload
        sale.reload

        remaining_depreciation = @fixed_asset.depreciations.first
        entry = remaining_depreciation.journal_entry
        debit_item = entry.items.where.not(debit: 0).first
        credit_item = entry.items.where.not(credit: 0).first

        assert_equal @fixed_asset.depreciations.count, 1
        assert_equal remaining_depreciation.stopped_on, @sold_on
        assert_equal entry.debit, 4.19
        assert_equal entry.credit, 4.19
        assert_equal credit_item.account_id, @fixed_asset.allocation_account_id
        assert_equal debit_item.account_id, @fixed_asset.expenses_account_id

        sell_entry = @fixed_asset.sold_journal_entry

        assert sell_entry

        asset_item = sell_entry.items.where(account: @fixed_asset.asset_account).first
        allocation_item = sell_entry.items.where(account: @fixed_asset.allocation_account).first
        asset_value_item = sell_entry.items.where(account: Account.find_by_number('67500000')).first

        assert asset_item
        assert allocation_item
        assert asset_value_item

        assert_equal asset_item.credit, 42.0
        assert_equal allocation_item.debit, 4.19
        assert_equal asset_value_item.debit, 37.81
      end

      def new_transition_for(fa, sold_on, **options)
        FixedAsset::Transitions::Sell.new(fa, sold_on: sold_on, **options)
      end

      def t_err(t)
        proc { raise t.error }
      end
    end
  end
end
