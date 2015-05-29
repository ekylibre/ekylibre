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

class Backend::VisualsController < Backend::BaseController
  skip_before_action :authenticate_user!
  skip_before_action :authorize_user!

  def picture
    if Ekylibre::CorporateIdentity::Visual.file?
      send_file(Ekylibre::CorporateIdentity::Visual.path)
    else
      head :not_found
    end
  end

end
