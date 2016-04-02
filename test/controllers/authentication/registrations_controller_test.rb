require "test_helper"

class Authentication::RegistrationsControllerTest < ActionController::TestCase
  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "should create a User with signup_at value" do
    post :create, user: { first_name: "Robert", last_name: "Tee", email: "robert.tee@gmail.com", password: "robert00", password_confirmation: "robert00", language: "eng" }

    user = User.where(first_name: "Robert", last_name: "Tee", email: "robert.tee@gmail.com", language: "eng").first
    assert_not_nil user
    assert_not_nil user.signup_at
    assert_response :redirect
  end
end
