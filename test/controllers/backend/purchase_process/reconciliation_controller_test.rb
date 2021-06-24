require 'test_helper'
module Backend
  module PurchaseProcess
    class ReconciliationControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      test_restfully_all_actions

      setup do
        Reception.delete_all
        PurchaseOrder.delete_all

        @supplier_one = create(:entity, :supplier)
        @supplier_two = create(:entity, :supplier)

        @reception_one = create(:reception, state: :draft, sender: @supplier_one)
        @reception_item_one = create(:reception_item, reception: @reception_one)

        @reception_two = create(:reception, state: :given, given_at: DateTime.new(2018, 1, 1), sender: @supplier_one)
        @reception_item_two = create(:reception_item, purchase_invoice_item_id: nil, reception: @reception_two)

        @purchase_invoice_one = create :purchase_invoice
        @purchase_item = create :purchase_item, purchase: @purchase_invoice_one

        @reception_three = create(:reception, state: :given, given_at: DateTime.new(2018, 1, 1), sender: @supplier_two)
        @reception_item_three = create(:reception_item, purchase_invoice_item_id: @purchase_item.id, reception: @reception_three)

        @purchase_order_one = create(:purchase_order, state: :opened, supplier: @supplier_one)
        @purchase_item_one = create(:purchase_item, :of_purchase_order, purchase: @purchase_order_one)

        @purchase_order_two = create(:purchase_order, supplier: @supplier_one)
        @purchase_order_two.close
        @purchase_item_two = create(:purchase_item, :of_purchase_order, purchase: @purchase_order_two)

        @purchase_order_three = create(:purchase_order, supplier: @supplier_two)
        @purchase_order_three.close
        @purchase_item_three = create(:purchase_item, :of_purchase_order, purchase: @purchase_order_three)
      end

      test "if the supplier is set then only given receptions from this supplier appear in the purchase invoice form modal and could be reconciled" do
        get :receptions_to_reconciliate, params: { supplier: @supplier_one.id }
        assert_response 200

        parsing_response_reception = Nokogiri::HTML(response.body)
        reception_ids = parsing_response_reception.css('input[type="checkbox"].model-checkbox').map { |k, v| k["data-id"].to_i }

        assert_includes reception_ids, @reception_two.id
        refute_includes reception_ids, @reception_one.id
        refute_includes reception_ids, @reception_three.id
      end

      test "only reception items not reconciled could be reconciled" do
        get :receptions_to_reconciliate, params: { supplier: @supplier_two.id }
        assert_response 200

        parsing_response_reception = Nokogiri::HTML(response.body)
        reception_ids = parsing_response_reception.css('input[type="checkbox"].item-checkbox').map { |k, v| k["data-id"].to_i }

        refute_includes reception_ids, @reception_item_three.id
      end

      test "if the supplier is set then only opened purchase_orders from this supplier appear in the reception form modal and could be reconciled" do
        get :purchase_orders_to_reconciliate, params: { supplier: @supplier_one.id }
        assert_response 200

        parsing_response_purchase_order = Nokogiri::HTML(response.body)
        purchase_order_ids = parsing_response_purchase_order.css('input[type="checkbox"].model-checkbox').map { |k, v| k["data-id"].to_i }

        assert_includes purchase_order_ids, @purchase_order_one.id
        refute_includes purchase_order_ids, @purchase_order_two.id
      end
    end
  end
end
