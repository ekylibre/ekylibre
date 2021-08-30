require 'test_helper'
module Api
  module V2
    module Lexicon
      class RegisteredPhytosanitaryRisksControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
        extend ActiveSupport::Concern
        connect_with_token

        test 'index' do
          get :index, params: {}
          json = JSON.parse response.body

          assert_equal RegisteredPhytosanitaryRisk.count, json["data"].count
          assert_response :ok
        end
      end
    end
  end
end
