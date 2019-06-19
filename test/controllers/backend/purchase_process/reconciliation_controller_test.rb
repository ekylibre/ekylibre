require 'test_helper'
module Backend
  module PurchaseProcess
    class ReconciliationControllerTest < ActionController::TestCase
      test_restfully_all_actions


      test 'reception to reconcile' do
        Reception.delete_all
        reception_one = create(:reception, state: :draft)
        reception_item_one = create(:reception_item, reception: reception_one)


        reception_two = create(:reception, state: :given, given_at: DateTime.now)
         reception_item_two = create(:reception_item, reception: reception_two)

         reception_three = create(:reception, state: :given, given_at: DateTime.now)
         reception_item_three = create(:reception_item, reception: reception_three)

        get :receptions_to_reconciliate
        assert_response 200

        parsing_response_reception = Nokogiri::HTML(response.body)
        reception_ids = parsing_response_reception.css('input[type="checkbox"].model-checkbox').map { |k, v| k["data-id"].to_i }

        assert_includes reception_ids, reception_two.id
        assert_includes reception_ids, reception_three.id
        refute_includes reception_ids, reception_one.id

      end
    end
  end
end
