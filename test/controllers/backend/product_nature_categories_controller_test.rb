require 'test_helper'

module Backend
  class ProductNatureCategoriesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: :edit

    # TODO: Re-activate following test

    # test 'should not raise exception on dual incorporate' do
    #   path = '/backend/product_nature_categories'
    #   request.env['HTTP_REFERER'] = "http://test.host#{path}"
    #   assert_nothing_raised do
    #     post :incorporate, params: { :product_nature_category => { 'reference_name' => 'animal_food' }, 'commit' => 'Importer' }
    #     assert_redirected_to path
    #     post :incorporate, params: { :product_nature_category => { 'reference_name' => 'animal_food' }, 'commit' => 'Importer' }
    #     assert_redirected_to path
    #   end
    # end
  end
end
