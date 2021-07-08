module Api
  module V2
    class UsersController < Api::V2::BaseController
      def show
        @user = current_user
        respond_with @user
      end
    end
  end
end
