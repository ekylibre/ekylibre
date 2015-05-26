require 'test_helper'
class Pasteque::V5::UsersControllerTest < ActionController::TestCase

  test "index" do
    get :index, login: "admin@ekylibre.org", password: "12345678", format: :json
  end

end
