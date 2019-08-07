require 'test_helper'
module Backend

  class ReceptionsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions give: :touch, except: :create

    test "a reception can't be created without at least one item" do
      sender_one = create(:entity, :supplier)
      post :create, reception: { sender_id: sender_one.id }

      # assert_not
      assert_response 200

      parsing_response_reception = Nokogiri::HTML(response.body)
      reception_error_notified = parsing_response_reception.css("div[data-alert='true']")
      reception_form = parsing_response_reception.css("form[id='new_reception']")


      assert reception_error_notified.present?
      assert reception_form.present?
    end
  end
end
