# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013-2015 Brice Texier, David Joulin
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
  class AnalysisItemsController < Backend::BaseController
    def new
      if request.xhr?
        unless indicator = Nomen::Indicator.find(params[:indicator_name])
          head :not_found
          return
        end
        unless @analysis = Analysis.find_by(id: params[:analysis_id])
          @analysis = Analysis.new
        end
        @analysis.items.build(indicator_name: indicator.name)
        render partial: 'nested_form'
      else
        redirect_to backend_root_path
      end
    end
  end
end
