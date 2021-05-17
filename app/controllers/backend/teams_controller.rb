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
  class TeamsController < Backend::BaseController
    manage_restfully except: :index

    unroll

    list(order: :name) do |t|
      t.action :edit
      t.action :destroy
      t.column :name
      t.column :description
      t.column :isacompta_analytic_code, hidden: AnalyticSegment.where(name: 'teams').none?
    end

    def index
      if segment = AnalyticSegment.find_by(name: 'teams')
        notify_warning(:fill_analytic_codes_of_your_segments.tl(segment: segment.name.text.downcase))
      end
      respond_to do |format|
        format.html
        format.xml  { render xml:  resource_model.all }
        format.json { render json: resource_model.all }
      end
    end
  end
end
