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

        test 'index with user product' do
          get :index, params: { user_product: 'true' }
          json = JSON.parse response.body

          phytosanitary_product=RegisteredPhytosanitaryProduct.where(reference_name: ProductNatureVariant.where.not(france_maaid: "").pluck(:reference_name)).distinct
          usages_product = RegisteredPhytosanitaryUsage.where(product_id: phytosanitary_product.pluck(:france_maaid).map(&:to_i))
          assert_equal usages_product.count, json["data"].count
          assert_response :ok
        end

        test 'index with modified_since params' do
          get :index, params: { modified_since: "29/03/2050" }
          json = JSON.parse response.body

          assert_equal 0, json["data"].count
          assert_response :ok
        end
      end
    end
  end
end
