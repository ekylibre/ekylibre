require 'test_helper'
module Pasteque
  module V5
    class UsersControllerTest < ActionController::TestCase
      test 'index' do
        get :index, login: 'admin@ekylibre.org', password: '12345678', format: :json
      end
    end
  end
end
