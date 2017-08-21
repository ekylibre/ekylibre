# encoding: utf-8

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
  module V1
    class TokensController < Api::V1::BaseController
      skip_before_action :authenticate_api_user!

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
