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
  class RegistrationsController < Backend::BaseController
    list(:registrations,
         model: :users,
         conditions: ["#{User.table_name}.signup_at IS NOT NULL"],
         order: 'users.last_name') do |t|
      t.action :edit, url: { action: :edit, controller: 'registrations' }
      t.action :destroy, if: '!RECORD.signup_at.nil?'.c
      t.column :first_name
      t.column :last_name
      t.column :email
      t.column :signup_at
    end

    # Need to add explicitly action to detect it properly for now
    def index; end

    def edit
      @registration = User.find(params[:id])
      @form_url = backend_registration_path(@registration)
    end

    def update
      @registration = User.find(params[:id])

      if @registration.update(approved_params)
        RegistrationMailer.approved(@registration).deliver_now
        redirect_to backend_registrations_path
      else
        @form_url = backend_registration_path(@registration)

        render :edit
      end
    end

    def destroy
      @user = User.find(params[:id])
      @user.destroy
      redirect_to backend_registrations_path
    end

    private

      def signup_params
        params.require(:user).permit(:first_name, :last_name, :language, :role_id)
      end

      def approved_params
        signup_params.merge(signup_at: nil)
      end
  end
end
