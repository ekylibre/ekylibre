module Api
  module V2
    class UsersController < Api::V2::BaseController
      # GET /api/v2/profile
      # Returns the full serialization of the currently authenticated user.
      #
      # Authentication: required.
      #
      # Responses:
      # - 200 OK  Full user record (Jbuilder template)
      def show
        @user = current_user
        respond_with @user
      end

      # GET /api/v2/users/me
      # Returns a minimal, stable session payload for external clients (e.g. Duke).
      # Distinct from #show which returns the full User serialization.
      #
      # Authentication: required.
      #
      # Responses:
      # - 200 OK  { id, email, full_name, locale, role }
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

      # PUT /api/v2/profile
      # Updates the profile of the currently authenticated user.
      #
      # Authentication: required.
      #
      # Request body params (all optional):
      # - first_name [String]
      # - last_name  [String]
      # - email      [String]
      # - language   [String] One of the available locales (e.g. "fra", "eng")
      #
      # Responses:
      # - 200 OK          { "id": <user_id> }
      # - 400 Bad Request { "errors": [<full error messages>] }
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
