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
    class BaseController < ::ApiController
      include ActionController::Flash

      wrap_parameters false
      respond_to :json

      before_action :authenticate_api_user!
      before_action :force_json!
      after_action :add_generic_headers!

      rescue_from ActionController::ParameterMissing, with: :rescue_param_missing
      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :rescue_bad_params

      def record_not_found(exception)
        render json: { errors: [exception.message] }, status: :not_found
      end

      def rescue_param_missing(exception)
        render json: { errors: [exception.message] }, status: :forbidden
      end

      def rescue_bad_params(exception)
        render json: { errors: exception.record.errors.full_messages }, status: :forbidden
      end

      protected

        def add_generic_headers!
          response.headers['X-Ekylibre-Media-Type'] = 'ekylibre.V2'
          # response.headers['Access-Control-Allow-Origin'] = '*'
        end

        def force_json!
          request.format = 'json'
        end

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

        # Initialize locale with params[:locale] or HTTP_ACCEPT_LANGUAGE
        def set_locale
          locale = Maybe(valid_locale_or_nil(current_user&.language))
                     .recover { valid_locale_or_nil(params.to_unsafe_hash.fetch(:locale, nil)) }
                     .recover { http_accept_language.compatible_language_from(Ekylibre.http_languages.keys) }
                     .recover { valid_locale_or_nil(Preference[:language]) }
                     .recover { I18n.default_locale }

          I18n.locale = session[:locale] = locale
        end

        # Check given token match with the user one and
        def authenticate_user_from_simple_token!(email, token)
          user = User.find_by(email: email)
          # Notice how we use Devise.secure_compare to compare the token
          # in the database with the token given in the params, mitigating
          # timing attacks.
          if user && Devise.secure_compare(user.authentication_token, token)
            # Sign in using token should not be tracked by Devise trackable
            # See https://github.com/plataformatec/devise/issues/953
            request.env['devise.skip_trackable'] = true
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

        def error_message(message, status: :bad_request)
          render json: { message: message }, status: status
        end

        def permitted_params
          params.except(:format)
        end

        def create_params
          begin
            provider_params = params.require(:provider)
            provider_params.require(%i[vendor name])
            provider_data = provider_params.permit(:id, :vendor, :name)
            if provider_params.key?(:data)
              provider_data[:data] = provider_params.require(:data).permit!
            end
            permitted_params.merge(provider: provider_data)
          rescue ActionController::ParameterMissing => e
            raise e.class.new("Provider param is invalid")
          end
        end

      private

        # Like `presence` but for valid locale strings
        #
        # @param [String, nil] locale
        # @return [String, nil]
        def valid_locale_or_nil(locale)
          if locale.present? && I18n.available_locales.include?(locale)
            locale
          else
            nil
          end
        end
    end
  end
end
