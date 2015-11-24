# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2014 Brice Texier, David Joulin
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
  class GuideAnalysesController < Backend::BaseController
    manage_restfully only: [:show], t3e: { guide: :guide_name }

    list(:points, model: :guide_analysis_points, conditions: { analysis_id: 'params[:id]'.c }, order: :id) do |t|
      t.column :reference_name
      t.status
      t.column :advice_reference_name
    end
  end
end
