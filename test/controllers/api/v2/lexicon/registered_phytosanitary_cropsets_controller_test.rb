require 'test_helper'
module Api
  module V2
    module Lexicon
      class RegisteredPhytosanitaryCropsetsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
        extend ActiveSupport::Concern
        connect_with_token

        test 'index' do
          get :index, params: {}
          json = JSON.parse response.body

          assert_equal RegisteredPhytosanitaryCropset.count, json["data"].count
          assert_response :ok
        end

        test 'create' do
          params = {
            data: [
                {
                    id: "9878888",
                    record_checksum: -457_845
                },
                {
                    id: "1",
                    record_checksum: -2_113_121_812
                },
                {
                    id: "2",
                    record_checksum: -2_126_897_566
                }
              ]
            }

          post :create, params: params
          json = JSON.parse response.body

          assert_equal({ "id"=>"9878888" }, json["data"].detect {|a| a["id"] == "9878888" })
          assert_equal 1, json["data"].last.keys.count

          assert(json["data"].detect {|a| a["id"] == "2" })
          assert_not_equal 1, json["data"].detect {|a| a["id"] == "2" }.keys.count

          assert_not_equal 1, json["data"].detect {|a| a["id"] == "3" }.keys.count
          assert(json["data"].detect {|a| a["id"] == "3" })
          assert json["data"].detect {|a| a["id"] == "1" }.nil?

          assert_response :ok
        end
      end
    end
  end
end
