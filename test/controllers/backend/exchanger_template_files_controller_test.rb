require 'test_helper'

module Backend
  class ExchangerTemplateFilesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    test_restfully_all_actions except: %i[show]

    setup do
      @user.update_column(:language, :fra)
    end

    test 'show action with unexisiting file' do
      assert_raises(ActionController::RoutingError) do
        get :show, id: 'none'
      end
    end

    test 'show action with exisiting file' do
      get :show, id: 'ekylibre_cvi_csv'
      assert 'csv', response.header['Content-Type']
    end
  end
end
