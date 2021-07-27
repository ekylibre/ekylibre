module Api
  module V2
    class UsersController < Api::V2::BaseController
      def show
        @user = current_user
        respond_with @user
      end

      def update
        @user = current_user
        if @user.update(permitted_params)
          render status: :ok, json: {  id: @user.id }
        else
          render status: :bad_request, json: { errors: @user.errors.full_messages }
        end
      end

      protected

        def permitted_params
          permitted = params.permit(
            :first_name,
            :last_name,
            :email,
            :language
          )
        end
    end
  end
end
