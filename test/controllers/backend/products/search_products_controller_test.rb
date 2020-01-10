require 'test_helper'
module Backend
  module Products
    class SearchProductsControllerTest < ActionController::TestCase
      test_restfully_all_actions except: :datas

      test 'nothing' do
      end
    end
  end
end
