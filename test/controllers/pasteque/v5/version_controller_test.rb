require 'test_helper'
module Pasteque
  module V5
    class VersionControllerTest < ActionController::TestCase
      test 'routes' do
        assert_recognizes({ controller: 'pasteque/v5/version', action: 'index', format: :json }, '/pasteque/v5/api.php?action=get&password=12345678&login=admin%40ekylibre.org&p=VersionAPI')
        assert_recognizes({ controller: 'pasteque/v5/version', action: 'index', format: :json }, '/pasteque/v5/api.php?action=get&p=VersionAPI')
      end

      test 'index' do
        get :index
        assert_response :success
        json = JSON.parse(@response.body).deep_symbolize_keys
        assert json[:content], "Response must contains :content: #{json.inspect}"
        assert_equal 5, json[:content][:level]
      end
    end
  end
end
