# frozen_string_literal: true

module Accountancy
  class AccountCategoryChanging
    attr_reader :result_infos
    # modes Array of String, could be ['sale', 'purchase', 'fixed_asset', 'fixed_asset_allocation', 'fixed_asset_expenses']
    # financial_year FinancialYear, default is FinancialYear.current
    # category ProductNatureCategory
    # variant_id Integer of ProductNatureVariant
    def initialize(category:, financial_year:, modes:, variant_id: nil)
      @category = category
      if variant_id.present?
        @variants = ProductNatureVariant.where(id: variant_id)
      else
        @variants = @category.variants
      end
      @financial_year = financial_year
      @started_on = @financial_year.started_on
      @stopped_on = @financial_year.stopped_on
      @started_at = @financial_year.started_on.to_time
      @stopped_at = @financial_year.stopped_on.to_time
      @modes = modes
      @result_infos = []
    end

    def perform
      @modes.each do |mode|
        update_items(mode)
      end
    end

    private

      def update_items(mode)
        if mode == 'purchase'
          category_label = mode
          count = purchase_items.count
          account_number = @category.charge_account.number
          purchase_items.update_all(account_id: @category.charge_account_id)
          Purchase.where(id: purchase_items.pluck(:purchase_id).uniq).map(&:save)
        elsif mode == 'sale'
          category_label = mode
          count = sale_items.count
          account_number = @category.product_account.number
          sale_items.update_all(account_id: @category.product_account_id)
          Sale.where(id: sale_items.pluck(:sale_id).uniq).map(&:save)
        elsif @category.storable? && mode.start_with?('stock')
          category_label = 'stock'
          count = @variants.count
          @variants.each do |variant|
            if mode == 'stock'
              variant.stock_account = variant.create_unique_account(:stock)
              account_number = @category.stock_account.number
            elsif mode == 'stock_movement'
              variant.stock_movement_account = variant.create_unique_account(:stock_movement)
              account_number = @category.stock_movement_account.number
            end
            variant.save!
          end
        elsif mode.start_with?('fixed_asset')
          category_label = 'fixed_asset'
          attrs = {}.with_indifferent_access
          count = fixed_assets_items.count
          if mode == 'fixed_asset'
            account_number = @category.fixed_asset_account.number
            attrs[:asset_account_id] = @category.fixed_asset_account_id
          elsif mode == 'fixed_asset_allocation'
            account_number = @category.fixed_asset_allocation_account.number
            attrs[:allocation_account_id] = @category.fixed_asset_allocation_account_id
          elsif mode == 'fixed_asset_expenses'
            account_number = @category.fixed_asset_expenses_account.number
            attrs[:expenses_account_id] = @category.fixed_asset_expenses_account_id
          end
          fixed_assets_items.update_all(attrs)
        end
        @result_infos << { mode: category_label, count: count, account_number: account_number }
      end

      def sale_items
        SaleItem.of_variants(@variants).between(@started_at, @stopped_at)
      end

      def sale_journal_entries
        JournalEntryItem.where(financial_year: @financial_year, variant_id: @variants.pluck(:id), resource_type: 'SaleItem', resource_prism: 'item_product')
      end

      def purchase_items
        PurchaseItem.of_variants(@variants).between(@started_at, @stopped_at)
      end

      def purchase_journal_entries
        JournalEntryItem.where(financial_year: @financial_year, variant_id: @variants.pluck(:id), resource_type: 'PurchaseItem', resource_prism: 'item_product')
      end

      def fixed_assets_items
        FixedAsset.draft_or_waiting.of_variants(@variants).start_between(@started_on, @stopped_on)
      end
  end
end
