require 'test_helper'
module Api
  module V1
    class VariantsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
      connect_with_token

      setup do
        [JournalEntryItem, ProductNatureVariant].each(&:delete_all)
        create_list(:product_nature_variant, 10, updated_at: '01/01/2016')
      end

      test 'get all records' do
        add_auth_header
        get :index
        variants = JSON.parse response.body
        assert_equal 10, variants.count
        assert_response :ok
      end

      test 'get records from a given date' do
        add_auth_header
        create_list(:product_nature_variant, 5, updated_at: '05/01/2017')
        modified_since = '01/01/2017'
        get :index, modified_since: modified_since
        variants = JSON.parse response.body
        assert_equal 5, variants.count
        assert_response :ok
      end
    end
  end
end
