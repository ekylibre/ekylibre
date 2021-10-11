require 'test_helper'
module Backend
  class PurchaseOrdersControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions open: :touch, close: :touch, except: %i[payment_mode create]

    test "an order can't be created without at least one item" do
      supplier_one = create(:entity, :supplier)
      post :create, params: { purchase_order: { supplier_id: supplier_one } }

      # assert_not
      assert_response 200

      parsing_response_purchase_order = Nokogiri::HTML(response.body)
      purchase_order_error_notified = parsing_response_purchase_order.css("div[data-alert='true']")
      purchase_order_form = parsing_response_purchase_order.css("form[id='new_purchase_order']")

      assert purchase_order_error_notified.present?
      assert purchase_order_form.present?
    end
  end
end
