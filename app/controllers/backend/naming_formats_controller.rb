# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2015 Brice Texier, David Joulin
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
  class NamingFormatsController < Backend::BaseController
    before_action :set_naming_format, only: [:update]

    manage_restfully subclass_inheritance: true

    def index
      @naming_formats_grid = initialize_grid(NamingFormat.all)
    end

    private

    def set_naming_format
      @naming_format = NamingFormat.find(params[:id])
    end
  end
end
