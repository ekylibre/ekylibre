# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2015 Brice Texier
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
  class JanusesController < Backend::BaseController
    # Saves the state of the kujakus
    def toggle
      face = params[:face].to_s
      janus = params[:id].to_s.strip
      if janus.blank?
        if request.post?
          head :not_found
        else
          raise ActionController::RoutingError, 'Not Found'
        end
      else
        default = params[:default]
        preference_name = "interface.janus.#{janus}.current_face"
        preference = current_user.preferences.find_by(name: preference_name)
        if default.blank? || (default.present? && face != default) ||
           (preference && face != preference.value.to_s)
          p = current_user.preference(preference_name, default)
          p.set!(face)
        end
        if request.post?
          head :ok
        else
          if params[:redirect]
            redirect_to(params[:redirect])
          else
            raise ActionController::RoutingError, 'Not Found'
          end
        end
      end
    end
  end
end
