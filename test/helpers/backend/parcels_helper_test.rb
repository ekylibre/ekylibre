require 'test_helper'

module Backend
  class ParcelsHelperTest < ActionView::TestCase
    test 'Purchase item with pretax amount > 0' do
      item = build(:parcel_item, unit_pretax_amount: 50)
      assert_equal  50, purchase_item_pretax_amount(item)
    end

    test 'Purchase item with pretax amount < 0' do
      item = build(:parcel_item, unit_pretax_amount: -5)
      assert_equal nil, purchase_item_pretax_amount(item)
    end

    test 'Item without amount and with purchase_item' do
      purchase = create(:purchase, nature: purchase_natures(:purchase_natures_001), tax_payability: 'at_invoicing')
      purchase_item = create(:purchase_item, purchase: purchase, tax: Tax.last, unit_pretax_amount: 75)
      parcel_item = create(:parcel_item, unit_pretax_amount: nil, purchase_item: purchase_item)
      assert_equal 75, purchase_item_pretax_amount(parcel_item)
    end
  end
end
