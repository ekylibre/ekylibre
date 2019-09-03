require 'test_helper'
module Backend

  class PurchaseInvoicesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions pay: { mode: :create, id: '20,21', mode_id: 1 }, except: %i[payment_mode create], update: { fixture: :second }

    # setup do
    #   PurchaseInvoice.delete_all
    # end

    test "an invoice can't be created without at least one item" do
      supplier_one = create(:entity, :supplier)
      post :create, purchase_invoice: { supplier_id: supplier_one }

      # assert_not
      assert_response 200

      parsing_response_purchase_invoice = Nokogiri::HTML(response.body)
      purchase_invoice_error_notified = parsing_response_purchase_invoice.css("div[data-alert='true']")
      purchase_invoice_form = parsing_response_purchase_invoice.css("form[id='new_purchase_invoice']")


      assert purchase_invoice_error_notified.present?
      assert purchase_invoice_form.present?
    end
  end
end
