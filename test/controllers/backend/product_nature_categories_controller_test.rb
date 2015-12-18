require 'test_helper'

module Backend
  class ProductNatureCategoriesControllerTest < ActionController::TestCase
    test_restfully_all_actions

    test 'should not raise exception on dual incorporate' do
      path = '/backend/product_nature_categories'
      request.env['HTTP_REFERER'] = "http://test.host#{path}"
      assert_nothing_raised do
        post :incorporate, :product_nature_category => { 'reference_name' => 'animal_food' }, 'commit' => 'Importer'
        assert_redirected_to path
        post :incorporate, :product_nature_category => { 'reference_name' => 'animal_food' }, 'commit' => 'Importer'
        assert_redirected_to path
      end
    end
  end
end
