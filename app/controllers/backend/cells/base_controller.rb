# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2012-2015 David Joulin, Brice Texier
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
  module Cells
    class BaseController < Backend::BaseController
      layout :wrap_cell

      rescue_from StandardError, with: :generic_exception
      protected

      def generic_exception
        render(inline: view_context.errored, status: :internal_server_error)
      end
      # Use a cell layout if asked
      def wrap_cell
        (params[:layout].to_i > 0 || params[:layout] == 'true') ? 'cell' : false
      end
    end
  end
end
