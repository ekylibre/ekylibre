require 'test_helper'
module Backend
  module Products
    class SearchProductsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      test_restfully_all_actions except: :datas

      test 'nothing' do
      end
    end
  end
end
