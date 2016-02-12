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
  class InvitationsController < ::Devise::InvitationsController
    before_filter :configure_permitted_parameters, if: :devise_controller?

    protected

    def configure_permitted_parameters
      # Only add some parameters
      devise_parameter_sanitizer.for(:invite).concat [:first_name, :last_name, :language, :role_id]

      # Override accepted parameters
      devise_parameter_sanitizer.for(:invite) do |u|
        u.permit(:first_name, :last_name, :language, :role_id, :email)
      end
    end
  end
end
