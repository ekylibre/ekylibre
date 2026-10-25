require 'test_helper'

module Backend
  # The new form can be filled by a caller (a plugin suggesting a purchase from a bank line).
  class QuickPurchasesPrefillTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    tests Backend::QuickPurchasesController

    setup do
      sign_in users(:users_001)
      @nature = purchase_natures(:purchase_natures_001)
      @item = bank_statement_items(:bank_statement_items_001)
      @supplier = entities(:entities_001)
      @variant = ProductNatureVariant.first
      @tax = Tax.first
    end

    test 'new fills the form from the trade and affair parameters' do
      get :new, params: {
        nature_id: @nature.id,
        bank_statement_item_ids: [@item.id],
        affair: { third_id: @supplier.id },
        trade: {
          reference_number: 'FA-42',
          description: 'Fuel',
          invoiced_at: '2026-09-30',
          items_attributes: { '0' => { variant_id: @variant.id, tax_id: @tax.id, conditioning_quantity: 1, unit_pretax_amount: 38.17, amount: 42, nature_id: 'x' } }
        }
      }
      assert_response :success
      trade = assigns(:trade)
      assert_equal 'FA-42', trade.reference_number
      assert_equal 'Fuel', trade.description
      assert_equal Date.new(2026, 9, 30), trade.invoiced_at.to_date
      assert_equal @nature.id, trade.nature_id
      assert_equal [@variant.id], trade.items.map(&:variant_id)
      assert_equal 42, trade.items.first.amount
      assert_equal @supplier, assigns(:affair).third
    end

    test 'new cannot be given another nature through the trade parameters' do
      other = purchase_natures(:purchase_natures_002)
      get :new, params: { nature_id: @nature.id, bank_statement_item_ids: [@item.id], trade: { nature_id: other.id } }
      assert_response :success
      assert_equal @nature.id, assigns(:trade).nature_id
    end

    test 'new keeps its defaults without prefill parameters' do
      get :new, params: { nature_id: @nature.id, bank_statement_item_ids: [@item.id] }
      assert_response :success
      assert_equal 1, assigns(:trade).items.size
      assert_nil assigns(:trade).reference_number
      assert_nil assigns(:affair).third
    end
  end
end
