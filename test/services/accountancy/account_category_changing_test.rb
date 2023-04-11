# frozen_string_literal: true

require 'test_helper'

module Accountancy
  class AccountCategoryChangingTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
    setup do
      I18n.locale = :fra
      FinancialYear.delete_all
      Preference.set!(:accounting_system, 'fr_pcga')
      @fy = create(:financial_year, year: 2023)
      @nature = SaleNature.find_or_create_by(currency: 'EUR')
      @client = Entity.normal.first
      @standard_vat = Tax.create!(
        name: 'Standard',
        amount: 20,
        nature: :normal_vat,
        collect_account: Account.find_or_create_by_number('45661'),
        deduction_account: Account.find_or_create_by_number('45671'),
        country: :fr
      )
    end

    test 'change sale account on category when sales already exist' do
      variant = ProductNatureVariant.import_from_lexicon('eggplant')
      sale = Sale.new(nature: @nature, client: @client, invoiced_at: DateTime.parse('2023-01-02T00:00:00Z'))
      sale.items.new(variant: variant,
                      compute_from: :unit_pretax_amount,
                      conditioning_quantity: 50.to_d,
                      unit_pretax_amount: 50.0,
                      conditioning_unit: variant.guess_conditioning[:unit],
                      tax: @standard_vat)
      sale.save!
      sale.propose!
      sale.confirm!
      assert_equal sale.items.first.account_id, variant.category.product_account.id
      account = Account.find_or_create_by_number('70200000')
      variant.category.update(product_account: account)
      # call service
      service = Accountancy::AccountCategoryChanging.new(category: variant.category, financial_year: @fy, modes: ['sale'])
      service.perform
      sale.reload
      assert_equal sale.items.first.account_id, account.id
    end

  end
end
