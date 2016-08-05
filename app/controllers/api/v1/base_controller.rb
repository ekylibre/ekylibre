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
    class BaseController < ::ApiController
      include ActionController::Flash

      wrap_parameters false
      respond_to :json

      before_action :authenticate_api_user!
      before_action :force_json!
      after_action :add_generic_headers!

      hide_action :add_generic_headers!
      def add_generic_headers!
        response.headers['X-Ekylibre-Media-Type'] = 'ekylibre.v1'
        # response.headers['Access-Control-Allow-Origin'] = '*'
      end

      hide_action :force_json!
      def force_json!
        request.format = 'json'
      end

      hide_action :authenticate_api_user!
      def authenticate_api_user!
        user = nil
        token = nil
        if authorization = request.headers['Authorization']
          keys = authorization.split(' ')
          if keys.first == 'simple-token'
            return authenticate_user_from_simple_token!(keys.second, keys.third)
          end
          render status: :bad_request, json: { message: 'Bad authorization.' }
          return false
        elsif params[:access_token] && params[:access_email]
          return authenticate_user_from_simple_token!(params[:access_email], params[:access_token])
        end
        render status: :unauthorized, json: { message: 'Unauthorized.' }
        false
      end

      hide_action :authenticate_user_from_simple_token!
      # Check given token match with the user one and
      def authenticate_user_from_simple_token!(email, token)
        user = User.find_by(email: email)
        # Notice how we use Devise.secure_compare to compare the token
        # in the database with the token given in the params, mitigating
        # timing attacks.
        if user && Devise.secure_compare(user.authentication_token, token)
          # Sign in using token should not be tracked by Devise trackable
          # See https://github.com/plataformatec/devise/issues/953
          env['devise.skip_trackable'] = true
          # Notice the store option defaults to false, so the entity
          # is not actually stored in the session and a token is needed
          # for every request. That behaviour can be configured through
          # the sign_in_token option.
          sign_in user, store: false
          return true
        end
        render status: :unauthorized, json: { message: 'Unauthorized.' }
        false
      end

      protected

      def permitted_params
        params.except(:format)
      end
    end
  end
end
