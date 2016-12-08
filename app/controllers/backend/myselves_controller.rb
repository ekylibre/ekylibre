# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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

module Backend
  class MyselvesController < Backend::BaseController
    before_action :find_resource

    def show; end

    def update
      permitted_params = params.require(:user).permit(:first_name, :last_name, :language, :theme)
      if @user.update_attributes(permitted_params)
        I18n.locale = permitted_params[:language]
        notify_success :update_is_done
        redirect_to action: :show
      else
        render 'show'
      end
    end

    def change_password
      permitted_params = params.require(:user).permit(:current_password, :password, :password_confirmation)
      if @user.update_with_password(permitted_params)
        notify_success :update_is_done
        sign_in @user, bypass: true
        redirect_to action: :show
      else
        render 'show'
      end
    end

    protected

    def find_resource
      @user = User.find(current_user.id)
    end
  end
end
