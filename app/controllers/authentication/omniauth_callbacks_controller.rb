# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2013 Brice Texier
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

module Authentication
  class OmniauthCallbacksController < ::Devise::OmniauthCallbacksController
    def ekylibre
      @user = user_by_omniauth(request.env['omniauth.auth'])

      if @user
        accept_invitation if from_invitation?
        sign_in_and_redirect @user
      else
        set_flash_message :alert, :invalid, scope: 'devise.failure'
        session['devise.ekylibre_data'] = request.env['omniauth.auth']
        redirect_to new_user_session_path
      end
    end

    private

    def user_by_omniauth(auth)
      if from_invitation?
        User.find_by_invitation_token(invitation_token, true)
      else
        User.find_by(email: auth.info.email)
      end
    end

    def invitation_token
      @invitation_token ||= params[:invitation_token]
    end

    def from_invitation?
      invitation_token.present?
    end

    def accept_invitation
      @user.password = Devise.friendly_token[20]
      @user.accept_invitation!
    end
  end
end
