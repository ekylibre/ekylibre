# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2014 Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module Api
  module V2
    class TokensController < Api::V2::BaseController
      skip_before_action :authenticate_api_user!

      # POST /api/v2/tokens
      # Authenticates a user and returns an authentication token to be used
      # in subsequent requests via the `Authorization: simple-token <email> <token>` header.
      #
      # Request body params:
      # - email     [String, required] User email address
      # - password  [String, required] User password
      #
      # Responses:
      # - 200 OK            { "token": "<authentication_token>" }
      # - 400 Bad Request   Missing email or password
      # - 401 Unauthorized  Invalid email or password
      def create
        email = params[:email]
        password = params[:password]

        if email.blank? || password.blank?
          render status: :bad_request, json: { message: 'The request must contain the user email and password.' }
          return
        end

        unless @user = User.find_by(email: email.downcase)
          logger.info("User #{email} failed signin, user cannot be found.")
          render status: :unauthorized, json: { message: 'Invalid email or password.' }
          return
        end

        if @user.valid_password?(password)
          # This following line forbids simultaneous connections:
          if @user.authentication_token.blank?
            @user.update_column(:authentication_token, User.generate_authentication_token)
          end
          render json: { token: @user.authentication_token }
        else
          logger.info("User #{email} failed signin, password is invalid")
          render status: :unauthorized, json: { message: 'Invalid email or password.' }
        end
      end

      # DELETE /api/v2/tokens/:id
      # Invalidates an authentication token (logout).
      #
      # URL params:
      # - id  [String, required] The authentication token to invalidate
      #
      # Responses:
      # - 200 OK         { "token": "<token>" }
      # - 404 Not Found  Token does not match any user
      def destroy
        @user = User.find_by(authentication_token: params[:id])
        if @user
          @user.update_column(:authentication_token, nil)
          render status: :ok, json: { token: params[:id] }
        else
          logger.info('Token not found.')
          render status: :not_found, json: { message: 'Invalid token.' }
        end
      end
    end
  end
end
