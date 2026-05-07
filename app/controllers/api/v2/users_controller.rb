module Api
  module V2
    class UsersController < Api::V2::BaseController
      def show
        @user = current_user
        respond_with @user
      end

      # GET /api/v2/users/me
      # Stable, minimal session payload consumed by external clients (e.g. Duke).
      # Distinct from #show which returns the full User serialization.
      def me
        user = current_user
        render status: :ok, json: {
          id: user.id,
          email: user.email,
          full_name: user.full_name,
          locale: user.language,
          role: user.role&.name
        }
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
