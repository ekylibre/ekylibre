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
  class CobblersController < Backend::BaseController
    def update
      unless params['order']
        head :unprocessable_entity
        return
      end
      order = params['order'].to_a
      begin
        current_user.prefer!("cobbler.#{params[:id]}", { order: order }.deep_stringify_keys.to_yaml)
        head :ok
      rescue ActiveRecord::StaleObjectError
        head :locked
      end
    end
  end
end
