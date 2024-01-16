# frozen_string_literal: true

require 'test_helper'

module Accountancy
  class AccountingSystemChangingTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    setup do
      I18n.locale = :fra
      FinancialYear.delete_all
      Preference.set!(:accounting_system, 'fr_pcga')
      Preference.set!(:account_number_digits, 8)
      @fy_first = create(:financial_year, year: 2023, accounting_system: 'fr_pcga')
      @fy_last = create(:financial_year, year: 2024, accounting_system: 'fr_pcga')
      @invoiced_at = DateTime.parse('2024-01-02T00:00:00Z')
      @nature = PurchaseNature.first
      @supplier = Entity.normal.suppliers.first
      @standard_vat = Tax.create!(
        name: 'Standard',
        amount: 20,
        nature: :normal_vat,
        collect_account: Account.find_or_create_by_number('45661'),
        deduction_account: Account.find_or_create_by_number('45671'),
        country: :fr
      )

      # <item name="livestock_feed_matter_expenses" fr_pcga="6014" fr_pcg82="6014" fr_pcga2023="60114"/>
      @variant_1 = ProductNatureVariant.import_from_lexicon('cow_food')
      @variant_unit_1 = @variant_1.guess_conditioning[:unit]
      # <item name="animal_medicine_matter_expenses" fr_pcga="6015" fr_pcg82="6015" fr_pcga2023="60115"/>
      @variant_2 = ProductNatureVariant.import_from_lexicon('cow_medicine')
      @variant_unit_2 = @variant_2.guess_conditioning[:unit]
    end

    test 'change accounting system when purchase, category and entries exists' do

      items_attributes = [
        {
          tax: @standard_vat,
          variant: @variant_1,
          unit_pretax_amount: 1.0,
          conditioning_quantity: 150,
          conditioning_unit: @variant_unit_1
        },
        {
          tax: @standard_vat,
          variant: @variant_2,
          unit_pretax_amount: 15.0,
          conditioning_quantity: 10,
          conditioning_unit: @variant_unit_2
        }
      ]

      purchase = new_purchase(items_attributes: items_attributes)
      purchase.invoice
      purchase.reload
      jeis = purchase.journal_entry.items

      assert_equal @variant_1.category.charge_account.number, "6014"
      assert_equal purchase.items.where(variant_id: @variant_1.id).first.account_id, @variant_1.category.charge_account.id
      assert_equal jeis.where(variant_id: @variant_1.id).first.account.number, "6014"
      # call service
      # @fy_last.update(accounting_system: 'fr_pcga2023')
      service = Accountancy::AccountingSystemChanging.new(financial_year_id: @fy_last.id, old_accounting_system: 'fr_pcga', new_accounting_system: 'fr_pcga2023')
      service.perform

      @variant_1.category.reload
      purchase.reload
      jeis.reload

      assert_equal @variant_1.category.charge_account.number, "60114000"
      assert_equal purchase.items.where(variant_id: @variant_1.id).first.account_id, @variant_1.category.charge_account.id
      assert_equal jeis.where(variant_id: @variant_1.id).first.account.number, "60114000"
    end

    private

      def new_purchase(type: 'PurchaseInvoice', nature: nil, supplier: nil, invoiced_at: nil, currency: 'EUR', state: nil, items_attributes: nil)
        attributes = {
          type: type,
          nature: nature || @nature,
          supplier: supplier || @supplier,
          invoiced_at: invoiced_at || @invoiced_at,
          currency: currency,
          state: state,
          items_attributes: items_attributes || {}
        }

        Purchase.create!(attributes)
      end

  end
end
