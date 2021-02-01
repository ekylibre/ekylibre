require 'test_helper'
require_dependency Rails.root.join('app', 'models', 'fixed_asset')

class FixedAsset
  module Transitions
    class StandByTest < Ekylibre::Testing::ApplicationTestCase
      setup do
        [2018, 2019].each { |year| create :financial_year, year: year }
        @fixed_asset = create :fixed_asset, started_on: Date.new(2019, 1, 1)
        @waiting_on = Date.new(2018, 6, 30)
        @fixed_asset_from_purchase = create_fixed_asset_from_purchase
      end

      test 'should not allow to put an invalid FixedAsset on hold' do
        mock = Minitest::Mock.new
        mock.expect :state, :draft
        mock.expect :valid?, false
        mock.expect :waiting_on, nil

        t = new_transition_for mock, @waiting_on

        assert_not t.can_run?, "Should not be able to put an invalid FixedAsset on hold"
        assert_mock mock
      end

      test 'cannot put a FixedAsset on hold if the given waiting_on date is not during an opened FinancialYear' do
        mock = Minitest::Mock.new
        mock.expect :state, :draft
        mock.expect :valid?, true
        mock.expect :waiting_on, nil

        t = new_transition_for mock, Date.new(2017, 6, 30)

        assert_not t.can_run?
        assert_mock mock
      end

      test 'putting a FixedAsset (not generated from a PurchaseItem) on hold generates a JournalEntry' do
        @fixed_asset.update!(waiting_on: @waiting_on)
        @fixed_asset.stand_by

        refute_nil @fixed_asset.waiting_journal_entry_id
      end

      test 'putting a FixedAsset (generated from a PurchaseItem) on hold does not generate a JournalEntry' do
        fixed_asset = @fixed_asset_from_purchase

        fixed_asset.update!(waiting_on: @waiting_on)
        fixed_asset.stand_by

        assert_nil fixed_asset.waiting_journal_entry
      end

      test 'putting a FixedAsset (generated from a PurchaseItem) on hold generates a JournalEntry if a waiting_asset_account different from the generic one is specified' do
        fixed_asset = @fixed_asset_from_purchase

        fixed_asset.update!(waiting_on: @waiting_on, waiting_asset_account: Account.find_or_import_from_nomenclature(:outstanding_equipment_assets))
        fixed_asset.stand_by

        waiting_journal_entry = JournalEntry.find_by(printed_on: @waiting_on, real_debit: fixed_asset.depreciable_amount, real_credit: fixed_asset.depreciable_amount)
        assert waiting_journal_entry

        waiting_credit_item = waiting_journal_entry.items.where(real_credit: fixed_asset.depreciable_amount).first
        waiting_debit_item = waiting_journal_entry.items.where(real_debit: fixed_asset.depreciable_amount).first

        assert_equal waiting_credit_item.account, Account.find_or_import_from_nomenclature(:outstanding_assets)
        assert_equal waiting_debit_item.account, fixed_asset.waiting_asset_account

        fixed_asset.start_up
        in_use_journal_entry = fixed_asset.journal_entry

        in_use_credit_item = in_use_journal_entry.items.where(real_credit: fixed_asset.depreciable_amount).first
        in_use_debit_item = in_use_journal_entry.items.where(real_debit: fixed_asset.depreciable_amount).first

        assert_equal in_use_debit_item.account, fixed_asset.purchase_items.first.variant.category.fixed_asset_account
        assert_equal in_use_credit_item.account, fixed_asset.waiting_asset_account
      end

      test 'putting a FixedAsset (not generated from a PurchaseItem) on hold uses waiting_asset_account and special_imputation_asset_account to generate a JournalEntry if they are provided' do
        @fixed_asset.update!(waiting_on: @waiting_on,
                             waiting_asset_account: Account.find_or_import_from_nomenclature(:outstanding_equipment_assets),
                             special_imputation_asset_account: Account.find_or_import_from_nomenclature(:incorporeal_asset_revenues))
        @fixed_asset.stand_by

        journal_entry = JournalEntry.find_by(printed_on: @waiting_on, real_debit: @fixed_asset.depreciable_amount, real_credit: @fixed_asset.depreciable_amount)
        assert journal_entry

        credit_item = journal_entry.items.where(real_credit: @fixed_asset.depreciable_amount).first
        debit_item = journal_entry.items.where(real_debit: @fixed_asset.depreciable_amount).first

        assert_equal debit_item.account, Account.find_or_import_from_nomenclature(:outstanding_equipment_assets)
        assert_equal credit_item.account, Account.find_or_import_from_nomenclature(:incorporeal_asset_revenues)
      end

      private

        def new_transition_for(fa, waiting_on, **options)
          FixedAsset::Transitions::StandBy.new(fa, waiting_on, **options)
        end

        def create_fixed_asset_from_purchase
          create :journal, nature: :purchases
          equipment = create :equipment_variant
          purchase = create :purchase_invoice, invoiced_at: Date.new(2019, 1, 1)
          purchase_item = create :purchase_item, purchase: purchase, variant: equipment, fixed: true
          purchase_item.purchase.save
          purchase_item.reload
          purchase_item.fixed_asset
        end
    end
  end
end
