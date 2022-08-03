require 'test_helper'
module Backend
  class InvitationsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup do
      @user = users(:users_001)
      sign_in @user
    end

    test 'Create action with valid params' do
      params = {
        form_objects_backend_invitation:
          {
            first_name: FFaker::Name.first_name,
            last_name: FFaker::Name.last_name,
            email: FFaker::Internet.email,
            role_id: Role.first.id,
            language: "fra"
          }
      }
      user_mock = Minitest::Mock.new
      user_mock.expect(:call, nil, [Hash, @user])

      User.stub(:invite!, user_mock) do
        post :create, params: params
      end
      assert_response :redirect
      user_mock.verify
    end
  end
end
