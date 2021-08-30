require 'test_helper'
module Api
  module V2
    module Lexicon
      class RegisteredPhytosanitaryUsagesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
        extend ActiveSupport::Concern
        connect_with_token

        test 'index' do
          get :index, params: {}
          json = JSON.parse response.body

          assert_equal RegisteredPhytosanitaryUsage.count, json["data"].count
          assert_response :ok
        end

        test 'index with modified_since params' do
          get :index, params: { modified_since: "29/03/2021" }
          json = JSON.parse response.body

          assert_equal 0, json["data"].count
          assert_response :ok
        end
      end
    end
  end
end
